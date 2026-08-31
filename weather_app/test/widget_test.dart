import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/models/city.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/providers/theme_provider.dart';
import 'package:weather_app/screens/home_screen.dart';
import 'package:weather_app/theme/app_theme.dart';

void main() {
  group('WeatherModel.fromJson', () {
    test('lit les champs utiles d\'une reponse OpenWeatherMap', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'coord': <String, dynamic>{'lon': -17.44, 'lat': 14.69},
        'weather': <dynamic>[
          <String, dynamic>{'description': 'ciel dégagé', 'icon': '01d'},
        ],
        'main': <String, dynamic>{
          'temp': 27.5,
          'feels_like': 29.1,
          'temp_min': 25.0,
          'temp_max': 30.0,
          'pressure': 1012,
          'humidity': 74,
        },
        'wind': <String, dynamic>{'speed': 5.0, 'deg': 270},
        'clouds': <String, dynamic>{'all': 20},
        'dt': 1735660800,
      };

      final WeatherModel weather = WeatherModel.fromJson(
        json,
        city: defaultCities.first,
      );

      expect(weather.city.name, 'Dakar');
      expect(weather.temperature, 27.5);
      expect(weather.temperatureLabel, '28 °C');
      expect(weather.humidityLabel, '74 %');
      expect(weather.pressureLabel, '1012 hPa');
      expect(weather.formattedDescription, 'Ciel dégagé');
      // 270 degres = vent d'ouest.
      expect(weather.windLabel, contains('Ouest'));
      expect(weather.latitude, 14.69);
    });

    test('reste robuste si des blocs sont absents du JSON', () {
      final WeatherModel weather = WeatherModel.fromJson(
        <String, dynamic>{},
        city: defaultCities.first,
      );

      expect(weather.temperature, 0);
      // A defaut de coordonnees renvoyees, on garde celles du catalogue.
      expect(weather.latitude, defaultCities.first.latitude);
      expect(weather.iconCode, '01d');
    });
  });

  testWidgets('HomeScreen affiche le bouton de demarrage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const HomeScreen(),
        ),
      ),
    );

    expect(find.text('WeatherApp'), findsWidgets);
    expect(find.text('Démarrer l\'expérience'), findsOneWidget);
  });
}