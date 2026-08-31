import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/city.dart';
import '../models/request_state.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

/// Etape courante de l'experience meteo.
enum ExperienceStatus {
  /// Rien n'a encore ete lance (etat initial et etat apres reinitialisation).
  idle,

  /// La jauge se remplit et les appels reseau s'enchainent.
  running,

  /// Jauge a 100 % et toutes les villes ont recu une reponse : on affiche
  /// le tableau de resultats.
  completed,
}

/// Orchestre toute l'experience : jauge animee, messages d'attente et appels
/// echelonnes a l'API pour les cinq villes du catalogue.
class WeatherProvider extends ChangeNotifier {
  WeatherProvider({WeatherService? service, List<City>? cities})
      : _service = service ?? WeatherService(),
        cities = cities ?? defaultCities {
    _states = <String, RequestState<WeatherModel>>{
      for (final City city in this.cities) city.id: const RequestIdle(),
    };
  }

  // --- Reglages temporels -----------------------------------------------
  // Duree totale du remplissage de la jauge.
  static const Duration _gaugeDuration = Duration(seconds: 9);

  // Frequence de rafraichissement de la jauge (100 ms = animation fluide).
  static const Duration _gaugeTick = Duration(milliseconds: 100);

  // Intervalle entre deux appels API : les cinq villes sont interrogees
  // successivement pendant que la jauge se remplit.
  static const Duration _requestInterval = Duration(milliseconds: 1500);

  // Frequence de rotation des messages d'attente.
  static const Duration _messageInterval = Duration(milliseconds: 1800);

  /// Messages affiches en boucle sous la jauge.
  static const List<String> waitingMessages = <String>[
    'Nous téléchargeons les données…',
    'Connexion aux stations météo…',
    'Analyse des relevés de température…',
    'C\'est presque fini…',
    'Plus que quelques secondes avant d\'avoir le résultat…',
  ];

  final WeatherService _service;

  /// Villes suivies par l'experience.
  final List<City> cities;

  late Map<String, RequestState<WeatherModel>> _states;

  Timer? _gaugeTimer;
  Timer? _requestTimer;
  Timer? _messageTimer;

  double _progress = 0;
  int _messageIndex = 0;
  int _nextCityIndex = 0;
  ExperienceStatus _status = ExperienceStatus.idle;
  bool _disposed = false;

  /// Identifiant du cycle courant.
  ///
  /// Il est incremente a chaque demarrage : une reponse reseau tardive
  /// appartenant a un cycle precedent est ainsi ignoree au lieu de venir
  /// polluer l'affichage apres un « Recommencer ».
  int _runId = 0;

  // --- Lecture de l'etat -------------------------------------------------

  ExperienceStatus get status => _status;

  /// Avancement de la jauge, entre 0.0 et 1.0.
  double get progress => _progress;

  int get progressPercent => (_progress * 100).round();

  bool get isRunning => _status == ExperienceStatus.running;

  bool get isCompleted => _status == ExperienceStatus.completed;

  /// Message d'attente courant.
  String get waitingMessage => waitingMessages[_messageIndex];

  /// Etat de la requete d'une ville donnee.
  RequestState<WeatherModel> stateFor(City city) =>
      _states[city.id] ?? const RequestIdle();

  /// Nombre de villes deja recuperees avec succes.
  int get loadedCount =>
      _states.values.whereType<RequestSuccess<WeatherModel>>().length;

  int get cityCount => cities.length;

  /// Villes dont la requete a echoue.
  List<City> get failedCities => cities
      .where((City city) => stateFor(city) is RequestFailure<WeatherModel>)
      .toList(growable: false);

  bool get hasFailures => failedCities.isNotEmpty;

  /// Vrai quand chaque ville a recu une reponse (succes ou erreur).
  bool get _allRequestsTerminal =>
      _states.values.every((RequestState<WeatherModel> s) => s.isTerminal);

  // --- Pilotage de l'experience -----------------------------------------

  /// Demarre (ou relance) l'experience complete depuis zero.
  void start() {
    _cancelTimers();
    _runId++;

    _progress = 0;
    _messageIndex = 0;
    _nextCityIndex = 0;
    _status = ExperienceStatus.running;
    _states = <String, RequestState<WeatherModel>>{
      for (final City city in cities) city.id: const RequestIdle(),
    };
    _notify();

    final int runId = _runId;

    // 1. Remplissage regulier de la jauge.
    _gaugeTimer = Timer.periodic(_gaugeTick, (Timer timer) {
      if (runId != _runId) {
        timer.cancel();
        return;
      }
      final double step =
          _gaugeTick.inMilliseconds / _gaugeDuration.inMilliseconds;
      _progress = (_progress + step).clamp(0.0, 1.0);
      if (_progress >= 1.0) {
        timer.cancel();
        _gaugeTimer = null;
      }
      _notify();
      _completeIfReady();
    });

    // 2. Rotation des messages d'attente.
    _messageTimer = Timer.periodic(_messageInterval, (Timer timer) {
      if (runId != _runId) {
        timer.cancel();
        return;
      }
      _messageIndex = (_messageIndex + 1) % waitingMessages.length;
      _notify();
    });

    // 3. Appels API echelonnes : la premiere ville part tout de suite, les
    //    suivantes toutes les 1,5 s tant qu'il en reste.
    _launchRequest(cities[_nextCityIndex++], runId);
    _requestTimer = Timer.periodic(_requestInterval, (Timer timer) {
      if (runId != _runId || _nextCityIndex >= cities.length) {
        timer.cancel();
        _requestTimer = null;
        return;
      }
      _launchRequest(cities[_nextCityIndex++], runId);
    });
  }

  /// Remet tout a zero (jauge, messages, donnees) sans rien relancer.
  void reset() {
    _cancelTimers();
    _runId++;
    _progress = 0;
    _messageIndex = 0;
    _nextCityIndex = 0;
    _status = ExperienceStatus.idle;
    _states = <String, RequestState<WeatherModel>>{
      for (final City city in cities) city.id: const RequestIdle(),
    };
    _notify();
  }

  /// Bouton « Recommencer » : reinitialise puis relance immediatement.
  void restart() => start();

  /// Relance uniquement la requete d'une ville en erreur.
  void retryCity(City city) {
    if (stateFor(city) is! RequestFailure<WeatherModel>) return;
    _launchRequest(city, _runId);
  }

  /// Relance toutes les requetes en erreur.
  void retryFailedCities() {
    for (final City city in failedCities) {
      _launchRequest(city, _runId);
    }
  }

  /// Arrete les timers sans toucher aux donnees deja chargees.
  ///
  /// Appele lorsque l'ecran principal quitte l'arbre des widgets, afin de ne
  /// pas laisser tourner des timers en arriere-plan.
  void stopTimers() => _cancelTimers();

  // --- Interne -----------------------------------------------------------

  /// Lance l'appel reseau d'une ville et met a jour son etat.
  Future<void> _launchRequest(City city, int runId) async {
    if (runId != _runId) return;

    _states[city.id] = const RequestLoading<WeatherModel>();
    _notify();

    try {
      final WeatherModel weather = await _service.fetchWeather(city);
      // Le cycle a pu etre relance pendant l'attente reseau : dans ce cas la
      // reponse est perimee, on la jette.
      if (runId != _runId) return;
      _states[city.id] = RequestSuccess<WeatherModel>(weather);
    } on WeatherException catch (error) {
      if (runId != _runId) return;
      _states[city.id] = RequestFailure<WeatherModel>(
        error.message,
        isRetryable: error.isRetryable,
      );
    } catch (_) {
      if (runId != _runId) return;
      _states[city.id] = RequestFailure<WeatherModel>(
        'Erreur inattendue lors du chargement de ${city.name}.',
      );
    }

    _notify();
    _completeIfReady();
  }

  /// Passe en mode « resultats » quand la jauge est pleine ET que les cinq
  /// villes ont repondu (succes ou erreur).
  void _completeIfReady() {
    if (_status != ExperienceStatus.running) return;
    if (_progress < 1.0 || !_allRequestsTerminal) return;
    _cancelTimers();
    _status = ExperienceStatus.completed;
    _notify();
  }

  void _cancelTimers() {
    _gaugeTimer?.cancel();
    _requestTimer?.cancel();
    _messageTimer?.cancel();
    _gaugeTimer = null;
    _requestTimer = null;
    _messageTimer = null;
  }

  /// Notifie les widgets, sauf si le provider a deja ete detruit (une reponse
  /// reseau peut arriver apres la fermeture de l'application).
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    super.dispose();
  }
}