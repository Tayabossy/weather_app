import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app_routes.dart';
import 'providers/theme_provider.dart';
import 'providers/weather_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Obligatoire : on utilise des plugins (dotenv, shared_preferences) avant
  // d'appeler runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Chargement de la cle API depuis le fichier .env (declare comme asset dans
  // pubspec.yaml). Si le fichier est absent, on initialise dotenv a vide :
  // l'application demarre quand meme et affiche un message d'erreur clair
  // dans le tableau, au lieu de planter au lancement.
  try {
    // isOptional: true -> un fichier .env absent ou vide n'interrompt pas le
    // demarrage (utile tant que l'etudiant n'a pas cree son .env).
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (_) {
    dotenv.loadFromString(envString: '', isOptional: true);
  }

  // La preference de theme est lue avant le premier rendu : cela evite un
  // clignotement clair -> sombre au demarrage.
  final ThemeProvider themeProvider = ThemeProvider();
  await themeProvider.loadPreference();

  runApp(WeatherApp(themeProvider: themeProvider));
}

/// Racine de l'application : providers globaux, themes et routes nommees.
class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        // Le theme est cree avant runApp() (preference deja chargee) : on le
        // partage ici avec .value plutot que d'en instancier un nouveau.
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<WeatherProvider>(
          create: (_) => WeatherProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (BuildContext context, ThemeProvider theme, _) {
          return MaterialApp(
            title: 'WeatherApp',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.themeMode,
            // Interface en francais (libelles systeme : bouton retour,
            // selection de texte, etc.).
            locale: const Locale('fr'),
            supportedLocales: const <Locale>[Locale('fr'), Locale('en')],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRoutes.home,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}