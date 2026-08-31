import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../models/city.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/theme_toggle_button.dart';

/// Ecran d'accueil : presentation de l'application et lancement de
/// l'experience meteo.
///
/// Les elements apparaissent en cascade grace a des [FadeSlideIn] dont le
/// delai augmente de haut en bas.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('WeatherApp'),
        actions: const <Widget>[ThemeToggleButton()],
      ),
      body: AnimatedBackground(
        showClouds: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const FadeSlideIn(child: _AnimatedLogo()),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: Text(
                        'WeatherApp',
                        textAlign: TextAlign.center,
                        style: text.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 220),
                      child: Text(
                        'Bienvenue ! Cette application récupère en direct la '
                        'météo de ${defaultCities.length} villes du Sénégal '
                        'auprès d\'OpenWeatherMap, puis les localise sur une '
                        'carte interactive OpenStreetMap.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 320),
                      child: _StepsCard(),
                    ),
                    const SizedBox(height: 32),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 460),
                      child: _PulsingCallToAction(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.weather),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 580),
                      child: Text(
                        'Fait par : Fatou Taye NDIAYE et '
                        'Mouhamet Oumar Sissokho SY',
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo anime : le soleil tourne lentement pendant que le nuage flotte.
class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo();

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Un seul controller pilote les deux mouvements : le soleil fait un tour
    // complet par cycle, le nuage deux oscillations.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 120,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Transform.rotate(
                angle: t * 2 * math.pi,
                child: Icon(
                  Icons.wb_sunny_rounded,
                  size: 74,
                  color: AppTheme.accentColor.withValues(alpha: 0.95),
                ),
              ),
              Positioned(
                // Oscillation verticale de +/- 5 px.
                bottom: 8 + 5 * math.sin(t * 2 * math.pi * 2),
                child: Icon(Icons.cloud_rounded, size: 84, color: color),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bouton principal avec une legere pulsation, pour attirer le regard.
class _PulsingCallToAction extends StatefulWidget {
  const _PulsingCallToAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_PulsingCallToAction> createState() => _PulsingCallToActionState();
}

class _PulsingCallToActionState extends State<_PulsingCallToAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      // Amplitude volontairement faible (3 %) : le bouton respire sans
      // devenir agressif.
      scale: Tween<double>(begin: 1.0, end: 1.03).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: FilledButton.icon(
        onPressed: widget.onPressed,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Démarrer l\'expérience'),
      ),
    );
  }
}

/// Resume des trois etapes de l'experience.
class _StepsCard extends StatelessWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context) {
    const List<(IconData, String)> steps = <(IconData, String)>[
      (Icons.donut_large_rounded, 'Une jauge se remplit pendant le chargement'),
      (Icons.table_rows_rounded, 'Un tableau présente les relevés des villes'),
      (Icons.map_rounded, 'Chaque ville s\'ouvre sur une carte détaillée'),
    ];

    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          children: <Widget>[
            for (final (int index, (IconData icon, String label))
                in steps.indexed)
              // Chaque ligne entre a son tour, apres la carte elle-meme.
              FadeSlideIn(
                delay: Duration(milliseconds: 420 + index * 110),
                beginOffset: const Offset(-0.06, 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: <Widget>[
                      Icon(icon, color: scheme.primary, size: 22),
                      const SizedBox(width: 14),
                      Expanded(child: Text(label, style: text.bodyMedium)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}