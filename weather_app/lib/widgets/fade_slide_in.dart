import 'dart:async';

import 'package:flutter/material.dart';

/// Anime l'apparition d'un widget : fondu + glissement vers le haut.
///
/// En donnant un [delay] croissant a une serie d'elements, on obtient une
/// entree « en cascade » (les lignes du tableau apparaissent l'une apres
/// l'autre au lieu de surgir d'un bloc).
///
/// L'animation ne se joue qu'une fois, a la construction du widget.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.beginOffset = const Offset(0, 0.16),
  });

  final Widget child;

  /// Retard avant le demarrage, pour l'effet de cascade.
  final Duration delay;

  final Duration duration;

  /// Decalage de depart, exprime en fraction de la taille du widget.
  final Offset beginOffset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      // Le timer est conserve pour pouvoir etre annule : sans cela, un widget
      // detruit avant la fin du delai declencherait une animation sur un
      // controller deja libere.
      _startTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.beginOffset,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        ),
        child: widget.child,
      ),
    );
  }
}