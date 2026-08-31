import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gere le mode clair / sombre de l'application et le persiste.
///
/// Le choix est enregistre avec `shared_preferences` : il est donc conserve
/// d'une session a l'autre. Tant que l'utilisateur n'a rien choisi, on suit le
/// reglage du systeme ([ThemeMode.system]).
class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Charge la preference enregistree. Appele une fois au demarrage.
  Future<void> loadPreference() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_prefsKey);
      _themeMode = _decode(stored);
      notifyListeners();
    } catch (_) {
      // Si le stockage local est indisponible, on garde simplement le mode
      // systeme : ce n'est pas une erreur bloquante pour l'utilisateur.
    }
  }

  /// Applique un mode explicite et l'enregistre.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _encode(mode));
    } catch (_) {
      // Persistance best-effort : l'interface reste coherente sans elle.
    }
  }

  /// Bascule entre clair et sombre.
  ///
  /// [currentBrightness] est la luminosite reellement affichee : elle permet de
  /// basculer correctement meme lorsque le mode actif est [ThemeMode.system].
  Future<void> toggle(Brightness currentBrightness) {
    return setThemeMode(
      currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  static ThemeMode _decode(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}