import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/city.dart';
import '../models/request_state.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/weather_city_card.dart';
import '../widgets/weather_gauge.dart';

/// Ecran principal de l'experience.
///
/// Il possede deux etats successifs, pilotes par le [WeatherProvider] :
///  - chargement : jauge animee + message d'attente qui tourne en boucle ;
///  - resultats : tableau interactif des villes, la jauge etant remplacee
///    par le bouton « Recommencer ».
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  /// Reference conservee des l'initialisation : `context.read` n'est plus
  /// utilisable dans `dispose()`, alors qu'on doit y couper les timers.
  late final WeatherProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<WeatherProvider>();

    // `start()` appelle notifyListeners() immediatement : on attend la fin de
    // la premiere frame pour ne pas reconstruire l'arbre pendant son build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _provider.start();
    });
  }

  @override
  void dispose() {
    // L'utilisateur revient a l'accueil : inutile de laisser tourner la jauge
    // et les appels reseau en arriere-plan.
    _provider.stopTimers();
    super.dispose();
  }

  void _openDetail(WeatherModel weather) {
    Navigator.of(context).pushNamed(AppRoutes.detail, arguments: weather);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expérience météo'),
        actions: const <Widget>[ThemeToggleButton()],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: Consumer<WeatherProvider>(
            builder: (BuildContext context, WeatherProvider provider, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder:
                    (Widget child, Animation<double> animation) =>
                        FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: provider.isCompleted
                    ? _ResultsView(
                        key: const ValueKey<String>('results'),
                        provider: provider,
                        onOpenDetail: _openDetail,
                      )
                    : _LoadingView(
                        key: const ValueKey<String>('loading'),
                        provider: provider,
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Vue de chargement : jauge + message d'attente dynamique.
class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key, required this.provider});

  final WeatherProvider provider;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            WeatherGauge(
              percent: provider.progress,
              loadedCount: provider.loadedCount,
              cityCount: provider.cityCount,
            ),
            const SizedBox(height: 40),
            // Hauteur fixe : le texte change toutes les 1,8 s, sans reserve
            // d'espace la mise en page sauterait a chaque message.
            SizedBox(
              height: 64,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder:
                    (Widget child, Animation<double> animation) =>
                        FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  provider.waitingMessage,
                  // La cle change avec le texte : c'est ce qui declenche
                  // l'animation de transition entre deux messages.
                  key: ValueKey<String>(provider.waitingMessage),
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Text(
              '${provider.loadedCount} sur ${provider.cityCount} villes '
              'récupérées',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vue de resultats : bouton « Recommencer » puis tableau interactif.
class _ResultsView extends StatelessWidget {
  const _ResultsView({
    super.key,
    required this.provider,
    required this.onOpenDetail,
  });

  final WeatherProvider provider;
  final ValueChanged<WeatherModel> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        // La jauge a laisse la place au bouton de relance.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: FadeSlideIn(
            beginOffset: const Offset(0, -0.25),
            child: FilledButton.icon(
              onPressed: provider.restart,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Recommencer'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${provider.loadedCount}/${provider.cityCount} villes '
                  'chargées — appuyez sur une ligne pour le détail',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (provider.hasFailures)
                TextButton.icon(
                  onPressed: provider.retryFailedCities,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tout réessayer'),
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        // En-tete du tableau.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('VILLE / CONDITIONS', style: text.labelSmall),
              Text('TEMPÉRATURE', style: text.labelSmall),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: provider.cityCount,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final City city = provider.cities[index];
              final RequestState<WeatherModel> state = provider.stateFor(city);
              final WeatherModel? weather = state.dataOrNull;

              // Entree en cascade : chaque ligne apparait 90 ms apres la
              // precedente, ce qui donne un effet de « deroulement » du
              // tableau plutot qu'un affichage bloc.
              return FadeSlideIn(
                delay: Duration(milliseconds: 150 + index * 90),
                child: WeatherCityCard(
                  city: city,
                  state: state,
                  onTap: weather == null ? null : () => onOpenDetail(weather),
                  // Ne relance que la requete de cette ville.
                  onRetry: () => provider.retryCity(city),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}