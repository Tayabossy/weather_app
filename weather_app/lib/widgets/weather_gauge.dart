import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

/// Jauge circulaire animee affichee pendant le chargement.
///
/// Trois animations se superposent :
///  1. le remplissage, pilote par le `WeatherProvider` (un `Timer` fait
///     progresser [percent] toutes les 100 ms) ;
///  2. un halo qui « respire » derriere la jauge ;
///  3. une couronne de points en rotation lente, qui signale que le travail
///     est toujours en cours meme quand la progression est lente.
///
/// Les animations 2 et 3 sont purement decoratives : elles tournent en boucle
/// sur un controller local, independamment des donnees.
class WeatherGauge extends StatefulWidget {
  const WeatherGauge({
    super.key,
    required this.percent,
    required this.loadedCount,
    required this.cityCount,
  });

  /// Avancement entre 0.0 et 1.0.
  final double percent;

  /// Nombre de villes deja recuperees (affiche au centre de la jauge).
  final int loadedCount;

  final int cityCount;

  @override
  State<WeatherGauge> createState() => _WeatherGaugeState();
}

class _WeatherGaugeState extends State<WeatherGauge>
    with TickerProviderStateMixin {
  /// Pulsation du halo (aller-retour).
  late final AnimationController _pulse;

  /// Rotation continue de la couronne de points.
  late final AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final double safePercent = widget.percent.clamp(0.0, 1.0);

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // 1. Halo pulsant.
          AnimatedBuilder(
            animation: _pulse,
            builder: (BuildContext context, Widget? child) {
              final double t = Curves.easeInOut.transform(_pulse.value);
              return Container(
                width: 205 + 30 * t,
                height: 205 + 30 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.10 - 0.05 * t),
                ),
              );
            },
          ),

          // 2. Couronne de points en rotation.
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _orbit,
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  size: const Size(252, 252),
                  painter: _OrbitPainter(
                    rotation: _orbit.value,
                    color: scheme.primary,
                  ),
                );
              },
            ),
          ),

          // 3. Jauge de progression.
          CircularPercentIndicator(
            radius: 96,
            lineWidth: 14,
            // percent_indicator exige une valeur dans [0, 1].
            percent: safePercent,
            animation: true,
            // Interpole entre deux valeurs successives : le mouvement parait
            // continu alors que les mises a jour sont discretes (100 ms).
            animateFromLastPercent: true,
            animationDuration: 150,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: scheme.primary,
            backgroundColor: scheme.primary.withValues(alpha: 0.15),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${(safePercent * 100).round()} %',
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                // Le compteur de villes change par a-coups : un fondu adoucit
                // la transition.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '${widget.loadedCount} / ${widget.cityCount} villes',
                    key: ValueKey<int>(widget.loadedCount),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dessine une couronne de petits points, decalee par [rotation].
class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.rotation, required this.color});

  /// Rotation de 0.0 a 1.0 (= un tour complet).
  final double rotation;

  final Color color;

  static const int _dotCount = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 2 - 4;
    final double baseAngle = rotation * 2 * math.pi;

    for (int i = 0; i < _dotCount; i++) {
      final double angle = baseAngle + (i / _dotCount) * 2 * math.pi;
      // Les points s'estompent progressivement : cela cree une trainee qui
      // rend le sens de rotation lisible.
      final double alpha = 0.05 + 0.35 * (i / _dotCount);
      final Offset position = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(
        position,
        2.2,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.color != color;
}