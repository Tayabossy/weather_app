import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Carte interactive centree sur une ville, avec un marqueur.
///
/// Les tuiles proviennent d'OpenStreetMap : aucune cle d'API n'est requise,
/// contrairement a Google Maps. La mention de la source en bas a droite est
/// exigee par la licence ODbL d'OpenStreetMap.
class WeatherMap extends StatelessWidget {
  const WeatherMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.label,
    this.zoom = 10,
  });

  final double latitude;
  final double longitude;

  /// Nom affiche sous le marqueur.
  final String label;

  final double zoom;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final LatLng position = LatLng(latitude, longitude);

    return Stack(
      children: <Widget>[
        FlutterMap(
          options: MapOptions(
            initialCenter: position,
            initialZoom: zoom,
            minZoom: 2,
            maxZoom: 18,
            // La rotation est desactivee : elle desoriente sur mobile et
            // n'apporte rien pour une simple localisation.
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // Recommande par la politique d'usage des tuiles OSM.
              userAgentPackageName: 'sn.uidt.weather_app',
            ),
            MarkerLayer(
              markers: <Marker>[
                Marker(
                  point: position,
                  width: 140,
                  height: 62,
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.location_on,
                        size: 38,
                        color: scheme.error,
                        shadows: const <Shadow>[
                          Shadow(blurRadius: 6, color: Colors.black45),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        // Attribution OpenStreetMap (obligatoire).
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: scheme.surface.withValues(alpha: 0.75),
            child: Text(
              '© OpenStreetMap contributors',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ],
    );
  }
}