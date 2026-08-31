import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fond d'ecran vivant, partage par les trois ecrans.
///
/// Il superpose trois elements :
///  1. le degrade de base du theme (clair ou sombre) ;
///  2. des halos colores qui derivent lentement (peints au [CustomPaint],
///     donc sans creer de widgets a chaque frame) ;
///  3. optionnellement des nuages qui traversent l'ecran.
///
/// L'animation dure 24 s et tourne en boucle : le mouvement reste perceptible
/// sans distraire de la lecture des donnees.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    required this.child,
    this.showClouds = false,
  });

  final Widget child;

  /// Affiche des nuages derivants (utilise sur l'ecran d'accueil).
  final bool showClouds;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    // Indispensable : un controller non libere continue de consommer des
    // frames et empeche la liberation de l'ecran.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient(context),
      ),
      child: Stack(
        children: <Widget>[
          // Les halos ne doivent jamais intercepter les gestes de
          // l'utilisateur, d'ou IgnorePointer. RepaintBoundary isole leur
          // repeinture du reste de l'interface.
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    return CustomPaint(
                      painter: _OrbPainter(
                        progress: _controller.value,
                        primary: scheme.primary,
                        secondary: AppTheme.accentColor,
                        tertiary: scheme.tertiary,
                        intensity: isDark ? 0.30 : 0.22,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (widget.showClouds)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: Stack(
                    children: <Widget>[
                      _cloud(phase: 0.0, y: -0.62, scale: 1.0, alpha: 0.16),
                      _cloud(phase: 0.45, y: -0.28, scale: 0.7, alpha: 0.12),
                      _cloud(phase: 0.75, y: 0.55, scale: 1.3, alpha: 0.10),
                    ],
                  ),
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }

  /// Un nuage qui traverse l'ecran de gauche a droite en boucle.
  ///
  /// [phase] decale le depart de chaque nuage pour eviter qu'ils avancent
  /// tous ensemble ; [y] est la position verticale (-1 haut, 1 bas).
  Widget _cloud({
    required double phase,
    required double y,
    required double scale,
    required double alpha,
  }) {
    final Color color = Theme.of(context).colorScheme.onSurface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = (_controller.value + phase) % 1.0;
        return Align(
          // De -1.4 a 1.4 : le nuage entre et sort completement de l'ecran.
          alignment: Alignment(-1.4 + t * 2.8, y),
          child: child,
        );
      },
      child: Icon(
        Icons.cloud_rounded,
        size: 90 * scale,
        color: color.withValues(alpha: alpha),
      ),
    );
  }
}

/// Peint trois halos radiaux dont le centre suit une trajectoire circulaire.
class _OrbPainter extends CustomPainter {
  const _OrbPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.intensity,
  });

  /// Avancement du cycle, de 0.0 a 1.0.
  final double progress;

  final Color primary;
  final Color secondary;
  final Color tertiary;

  /// Opacite maximale des halos.
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    _paintOrb(canvas, size,
        color: primary, phase: 0.0, cx: 0.20, cy: 0.22, radius: 0.55);
    _paintOrb(canvas, size,
        color: secondary, phase: 0.35, cx: 0.82, cy: 0.30, radius: 0.42);
    _paintOrb(canvas, size,
        color: tertiary, phase: 0.68, cx: 0.55, cy: 0.85, radius: 0.50);
  }

  void _paintOrb(
    Canvas canvas,
    Size size, {
    required Color color,
    required double phase,
    required double cx,
    required double cy,
    required double radius,
  }) {
    final double angle = (progress + phase) * 2 * math.pi;
    // Trajectoire elliptique douce autour du point d'ancrage (cx, cy).
    final Offset center = Offset(
      size.width * (cx + 0.09 * math.sin(angle)),
      size.height * (cy + 0.07 * math.cos(angle * 0.8)),
    );
    final double r = size.shortestSide * radius;

    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: intensity),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primary != primary ||
      oldDelegate.intensity != intensity;
}