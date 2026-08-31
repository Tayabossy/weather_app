import 'package:flutter/material.dart';

import 'models/weather_model.dart';
import 'screens/home_screen.dart';
import 'screens/weather_detail_screen.dart';
import 'screens/weather_screen.dart';
import 'widgets/error_message.dart';

/// Table de routage de l'application (routes nommees).
///
/// Le passage par [onGenerateRoute] permet de typer les arguments de l'ecran
/// de detail et de renvoyer une page d'erreur explicite si la navigation est
/// mal formee, plutot que de laisser planter l'application.
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String weather = '/weather';
  static const String detail = '/detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _animatedRoute(const HomeScreen(), settings);

      case weather:
        return _animatedRoute(const WeatherScreen(), settings);

      case detail:
        final Object? arguments = settings.arguments;
        if (arguments is WeatherModel) {
          return _animatedRoute(
            WeatherDetailScreen(weather: arguments),
            settings,
          );
        }
        return _errorRoute(
          settings,
          'Aucune donnée météo n\'a été transmise à l\'écran de détail.',
        );

      default:
        return _errorRoute(settings, 'Route inconnue : ${settings.name}');
    }
  }

  /// Transition commune a tous les ecrans : fondu enchaine avec une legere
  /// remontee, plus doux que le glissement lateral par defaut de Material.
  ///
  /// [PageRouteBuilder] reste une [PageRoute] : les animations `Hero`
  /// (l'icone meteo qui vole vers l'ecran de detail) continuent de
  /// fonctionner normalement.
  static Route<dynamic> _animatedRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) =>
          page,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final CurvedAnimation curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Route<dynamic> _errorRoute(RouteSettings settings, String message) {
    return MaterialPageRoute<void>(
      builder: (BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Navigation')),
        body: ErrorMessage(
          title: 'Page indisponible',
          message: message,
          retryLabel: 'Retour à l\'accueil',
          onRetry: () => Navigator.of(context)
              .pushNamedAndRemoveUntil(home, (Route<dynamic> route) => false),
        ),
      ),
      settings: settings,
    );
  }
}