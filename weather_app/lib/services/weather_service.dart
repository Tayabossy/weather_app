import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/city.dart';
import '../models/weather_model.dart';

/// Erreur metier deja traduite, prete a etre affichee dans l'interface.
///
/// Le reste de l'application ne manipule jamais une [DioException] : tout est
/// converti ici, ce qui evite d'afficher une stack trace a l'utilisateur.
class WeatherException implements Exception {
  const WeatherException(this.message, {this.isRetryable = true});

  final String message;

  /// `false` quand relancer la meme requete ne peut pas resoudre le probleme
  /// (cle API absente du fichier .env, par exemple).
  final bool isRetryable;

  @override
  String toString() => 'WeatherException: $message';
}

/// Acces a l'API "current weather data" d'OpenWeatherMap via Dio.
class WeatherService {
  /// [client] permet d'injecter un Dio simule dans les tests.
  WeatherService({Dio? client}) : _dio = client ?? Dio() {
    _dio.options
      ..baseUrl = _baseUrl
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 10)
      // On accepte tous les codes < 500 pour traiter nous-memes les 401/404
      // avec un message dedie plutot qu'une exception generique.
      ..validateStatus = (int? status) => status != null && status < 500;
  }

  static const String _defaultBaseUrl =
      'https://api.openweathermap.org/data/2.5';
  static const String _placeholderKey = 'your_key_here';

  final Dio _dio;

  /// Lecture defensive du fichier .env : renvoie `null` si dotenv n'a pas pu
  /// etre initialise ou si la variable est absente/vide.
  static String? _readEnv(String key) {
    if (!dotenv.isInitialized) return null;
    final String? value = dotenv.maybeGet(key)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  static String get _baseUrl => _readEnv('OPENWEATHER_BASE_URL') ?? _defaultBaseUrl;

  static String get _units => _readEnv('OPENWEATHER_UNITS') ?? 'metric';

  static String get _lang => _readEnv('OPENWEATHER_LANG') ?? 'fr';

  static String? get _apiKey {
    final String? key = _readEnv('OPENWEATHER_API_KEY');
    return key == _placeholderKey ? null : key;
  }

  /// Indique si une cle exploitable a ete trouvee dans le fichier `.env`.
  static bool get hasApiKey => _apiKey != null;

  /// Recupere la meteo courante d'une [city].
  ///
  /// La requete se fait par latitude/longitude : c'est plus fiable qu'une
  /// recherche par nom, qui peut correspondre a plusieurs communes.
  ///
  /// Leve une [WeatherException] en cas de probleme reseau ou serveur.
  Future<WeatherModel> fetchWeather(City city) async {
    final String? key = _apiKey;
    if (key == null) {
      throw const WeatherException(
        'Cle API absente. Copiez .env.example en .env puis renseignez '
        'OPENWEATHER_API_KEY avant de relancer l\'application.',
        isRetryable: false,
      );
    }

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/weather',
        queryParameters: <String, dynamic>{
          'lat': city.latitude,
          'lon': city.longitude,
          'appid': key,
          'units': _units,
          'lang': _lang,
        },
      );

      final int status = response.statusCode ?? 0;
      if (status != 200) {
        throw WeatherException(
          _messageForStatus(status, city),
          isRetryable: status != 404,
        );
      }

      final dynamic data = response.data;
      if (data is! Map) {
        throw WeatherException(
          'Reponse inattendue du serveur pour ${city.name}.',
        );
      }

      return WeatherModel.fromJson(
        data.cast<String, dynamic>(),
        city: city,
      );
    } on DioException catch (error) {
      throw WeatherException(_messageForDioError(error, city));
    } on WeatherException {
      rethrow;
    } catch (_) {
      throw WeatherException(
        'Impossible de lire les donnees meteo de ${city.name}.',
      );
    }
  }

  /// Traduit un code HTTP en message comprehensible.
  String _messageForStatus(int status, City city) {
    return switch (status) {
      401 => 'Cle API refusee (401). Verifiez OPENWEATHER_API_KEY dans le '
          'fichier .env : une cle recemment creee peut mettre jusqu\'a 2 h '
          'avant d\'etre activee.',
      404 => 'Aucune donnee meteo disponible pour ${city.name} (404).',
      429 => 'Quota d\'appels depasse (429). Patientez une minute avant de '
          'reessayer.',
      _ => 'Le serveur a repondu avec le code $status pour ${city.name}.',
    };
  }

  /// Traduit une erreur Dio (timeout, absence de reseau, erreur serveur...).
  String _messageForDioError(DioException error, City city) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Delai depasse pour ${city.name}. La connexion semble trop lente.',
      DioExceptionType.connectionError =>
        'Pas de connexion Internet. Verifiez votre reseau puis reessayez.',
      DioExceptionType.badCertificate =>
        'Certificat de securite refuse lors de l\'appel a OpenWeatherMap.',
      DioExceptionType.cancel => 'Requete annulee pour ${city.name}.',
      DioExceptionType.badResponse => _messageForStatus(
          error.response?.statusCode ?? 0,
          city,
        ),
      // Couvre DioExceptionType.unknown et les types ajoutes par Dio.
      _ => 'Erreur reseau pour ${city.name}. Verifiez votre connexion.',
    };
  }
}