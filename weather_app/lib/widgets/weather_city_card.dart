import 'package:flutter/material.dart';

import '../models/city.dart';
import '../models/request_state.dart';
import '../models/weather_model.dart';
import 'error_message.dart';
import 'weather_icon.dart';

/// Ligne du tableau de resultats pour une ville.
///
/// Le rendu depend de l'etat de la requete. Comme [RequestState] est une
/// `sealed class`, le `switch` ci-dessous est verifie par le compilateur :
/// aucun cas ne peut etre oublie.
class WeatherCityCard extends StatelessWidget {
  const WeatherCityCard({
    super.key,
    required this.city,
    required this.state,
    this.onTap,
    this.onRetry,
  });

  final City city;
  final RequestState<WeatherModel> state;

  /// Ouvre l'ecran de detail (uniquement si les donnees sont disponibles).
  final VoidCallback? onTap;

  /// Relance la requete de cette seule ville.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (state) {
      RequestIdle<WeatherModel>() => _PendingRow(
          city: city,
          label: 'En attente…',
          leading: const Icon(Icons.hourglass_empty, size: 22),
        ),
      RequestLoading<WeatherModel>() => _PendingRow(
          city: city,
          label: 'Chargement des données…',
          leading: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      RequestSuccess<WeatherModel>(:final WeatherModel data) =>
        _SuccessRow(weather: data),
      RequestFailure<WeatherModel>(
        :final String message,
        :final bool isRetryable
      ) =>
        _FailureRow(
          city: city,
          message: message,
          onRetry: isRetryable ? onRetry : null,
        ),
    };

    final bool tappable = state is RequestSuccess<WeatherModel> && onTap != null;

    return Card(
      child: InkWell(
        onTap: tappable ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: content,
        ),
      ),
    );
  }
}

/// Ligne « en attente » ou « chargement ».
class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.city,
    required this.label,
    required this.leading,
  });

  final City city;
  final String label;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        SizedBox(width: 46, child: Center(child: leading)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                city.name,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                label,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ligne complete : icone, ville, description, temperature.
class _SuccessRow extends StatelessWidget {
  const _SuccessRow({required this.weather});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        // Hero : l'icone « vole » de la ligne du tableau vers l'ecran de
        // detail. Le tag doit etre unique a l'ecran, d'ou l'id de la ville.
        Hero(
          tag: 'weather-icon-${weather.city.id}',
          child: WeatherIcon(iconCode: weather.iconCode, size: 46),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                weather.city.name,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                weather.formattedDescription,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            // La temperature defile de 0 jusqu'a sa valeur reelle a
            // l'apparition de la ligne. TweenAnimationBuilder ne rejoue
            // l'animation que si la valeur cible change : les rebuilds dus
            // aux autres villes ne la relancent pas.
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: weather.temperature),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double value, Widget? child) {
                return Text(
                  '${value.round()} °C',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                );
              },
            ),
            Text(
              'Ressenti ${weather.feelsLikeLabel}',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
      ],
    );
  }
}

/// Ligne en erreur, avec bouton « Reessayer » pour cette ville uniquement.
class _FailureRow extends StatelessWidget {
  const _FailureRow({
    required this.city,
    required this.message,
    this.onRetry,
  });

  final City city;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          city.name,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        ErrorMessage.compact(message: message, onRetry: onRetry),
      ],
    );
  }
}