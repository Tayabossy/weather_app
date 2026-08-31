import 'package:flutter/material.dart';

/// Icone meteo officielle d'OpenWeatherMap, chargee depuis le reseau.
///
/// Si l'image ne peut pas etre telechargee (mode avion, tuile indisponible),
/// on retombe sur une icone Material equivalente : l'interface reste lisible.
class WeatherIcon extends StatelessWidget {
  const WeatherIcon({
    super.key,
    required this.iconCode,
    this.size = 48,
  });

  /// Code renvoye par l'API, ex : "01d" (ciel degage, jour).
  final String iconCode;

  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        'https://openweathermap.org/img/wn/$iconCode@2x.png',
        fit: BoxFit.contain,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          return Icon(fallbackIconFor(iconCode), size: size * 0.8, color: color);
        },
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? progress,
        ) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  /// Correspondance entre les codes OpenWeatherMap et les icones Material.
  ///
  /// Les deux premiers caracteres portent la condition, le troisieme le
  /// moment de la journee ("d" pour jour, "n" pour nuit).
  static IconData fallbackIconFor(String code) {
    final String condition = code.length >= 2 ? code.substring(0, 2) : '01';
    final bool isNight = code.endsWith('n');

    return switch (condition) {
      '01' => isNight ? Icons.nightlight_round : Icons.wb_sunny,
      '02' => isNight ? Icons.nights_stay : Icons.wb_cloudy,
      '03' => Icons.cloud,
      '04' => Icons.cloud_queue,
      '09' => Icons.grain,
      '10' => Icons.umbrella,
      '11' => Icons.flash_on,
      '13' => Icons.ac_unit,
      '50' => Icons.foggy,
      _ => Icons.wb_cloudy,
    };
  }
}