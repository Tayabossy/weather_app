import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../models/weather_model.dart';
import '../widgets/animated_background.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/info_tile.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/weather_icon.dart';
import '../widgets/weather_map.dart';

/// Fiche detaillee d'une ville : tous les releves meteo et la localisation
/// exacte sur une carte OpenStreetMap.
class WeatherDetailScreen extends StatelessWidget {
  const WeatherDetailScreen({super.key, required this.weather});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(weather.city.name),
        actions: <Widget>[
          IconButton(
            tooltip: 'Retour à l\'accueil',
            icon: const Icon(Icons.home_rounded),
            // Depile toutes les routes jusqu'a l'accueil, quel que soit
            // l'endroit d'ou l'on vient.
            onPressed: () => Navigator.of(context).popUntil(
              ModalRoute.withName(AppRoutes.home),
            ),
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: <Widget>[
              FadeSlideIn(child: _HeaderCard(weather: weather)),
              const SizedBox(height: 20),
              const FadeSlideIn(
                delay: Duration(milliseconds: 140),
                child: _SectionTitle(
                  icon: Icons.thermostat_rounded,
                  label: 'Relevés détaillés',
                ),
              ),
              const SizedBox(height: 10),
              _DetailsGrid(weather: weather),
              const SizedBox(height: 24),
              const FadeSlideIn(
                delay: Duration(milliseconds: 620),
                child: _SectionTitle(
                  icon: Icons.public_rounded,
                  label: 'Localisation',
                ),
              ),
              const SizedBox(height: 6),
              FadeSlideIn(
                delay: const Duration(milliseconds: 680),
                child: Text(
                  'Coordonnées : ${weather.coordinatesLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 740),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 300,
                    child: WeatherMap(
                      latitude: weather.latitude,
                      longitude: weather.longitude,
                      label: weather.city.name,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau principal : icone, temperature et description.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.weather});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            // Meme tag que dans la ligne du tableau : l'icone effectue une
            // transition continue d'un ecran a l'autre.
            Hero(
              tag: 'weather-icon-${weather.city.id}',
              child: WeatherIcon(iconCode: weather.iconCode, size: 88),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    weather.temperatureLabel,
                    style: text.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    weather.formattedDescription,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${weather.city.name} (${weather.city.country}) — relevé '
                    'de ${weather.measuredAtLabel}',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grille des mesures secondaires.
class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.weather});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    final List<InfoTile> tiles = <InfoTile>[
      InfoTile(
        icon: Icons.device_thermostat,
        label: 'Ressenti',
        value: weather.feelsLikeLabel,
      ),
      InfoTile(
        icon: Icons.water_drop_outlined,
        label: 'Humidité',
        value: weather.humidityLabel,
      ),
      InfoTile(
        icon: Icons.air_rounded,
        label: 'Vent',
        value: weather.windLabel,
      ),
      InfoTile(
        icon: Icons.speed_rounded,
        label: 'Pression',
        value: weather.pressureLabel,
      ),
      InfoTile(
        icon: Icons.cloud_outlined,
        label: 'Nuages',
        value: weather.cloudinessLabel,
      ),
      InfoTile(
        icon: Icons.compare_arrows_rounded,
        label: 'Min / Max',
        value: weather.minMaxLabel,
      ),
    ];

    // `mainAxisExtent` fixe la hauteur des tuiles : plus sur qu'un ratio,
    // qui pourrait deborder sur les petits ecrans.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 76,
      ),
      itemCount: tiles.length,
      itemBuilder: (BuildContext context, int index) => FadeSlideIn(
        delay: Duration(milliseconds: 220 + index * 70),
        child: tiles[index],
      ),
    );
  }
}

/// Petit titre de section avec icone.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}