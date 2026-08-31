import 'city.dart';

/// Donnees meteo d'une ville, issues de l'endpoint
/// `https://api.openweathermap.org/data/2.5/weather` d'OpenWeatherMap.
class WeatherModel {
  const WeatherModel({
    required this.city,
    required this.temperature,
    required this.feelsLike,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDegree,
    required this.cloudiness,
    required this.description,
    required this.iconCode,
    required this.latitude,
    required this.longitude,
    required this.measuredAt,
  });

  /// Ville de notre catalogue a l'origine de la requete.
  final City city;

  /// Temperature en degres Celsius (parametre `units=metric`).
  final double temperature;

  /// Temperature ressentie en degres Celsius.
  final double feelsLike;

  final double temperatureMin;
  final double temperatureMax;

  /// Humidite relative en pourcentage.
  final int humidity;

  /// Pression atmospherique en hPa.
  final int pressure;

  /// Vitesse du vent renvoyee en m/s par l'API.
  final double windSpeed;

  /// Direction du vent en degres (0 = nord, 90 = est...).
  final int windDegree;

  /// Couverture nuageuse en pourcentage.
  final int cloudiness;

  /// Description localisee (parametre `lang=fr`), ex : "ciel degage".
  final String description;

  /// Code icone OpenWeatherMap, ex : "01d", "10n".
  final String iconCode;

  /// Coordonnees renvoyees par l'API (utilisees pour centrer la carte).
  final double latitude;
  final double longitude;

  /// Date/heure de la mesure cote serveur.
  final DateTime measuredAt;

  /// Construit le modele a partir du JSON brut de l'API.
  ///
  /// La [city] est passee explicitement afin de conserver le libelle de notre
  /// catalogue : interroge par coordonnees, OpenWeatherMap renvoie parfois le
  /// nom de la station meteo la plus proche plutot que celui de la ville.
  factory WeatherModel.fromJson(Map<String, dynamic> json, {required City city}) {
    final Map<String, dynamic> main =
        (json['main'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final Map<String, dynamic> wind =
        (json['wind'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final Map<String, dynamic> clouds =
        (json['clouds'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final Map<String, dynamic> coord =
        (json['coord'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    // Le bloc "weather" est une liste : le premier element porte la condition
    // dominante (les suivants sont des phenomenes secondaires).
    final List<dynamic> weatherList = (json['weather'] as List?) ?? const [];
    final Map<String, dynamic> weather = weatherList.isNotEmpty
        ? (weatherList.first as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    return WeatherModel(
      city: city,
      temperature: _toDouble(main['temp']),
      feelsLike: _toDouble(main['feels_like']),
      temperatureMin: _toDouble(main['temp_min']),
      temperatureMax: _toDouble(main['temp_max']),
      humidity: _toInt(main['humidity']),
      pressure: _toInt(main['pressure']),
      windSpeed: _toDouble(wind['speed']),
      windDegree: _toInt(wind['deg']),
      cloudiness: _toInt(clouds['all']),
      description: (weather['description'] as String?)?.trim().isNotEmpty == true
          ? weather['description'] as String
          : 'Donnee indisponible',
      iconCode: (weather['icon'] as String?) ?? '01d',
      latitude: coord['lat'] != null ? _toDouble(coord['lat']) : city.latitude,
      longitude: coord['lon'] != null ? _toDouble(coord['lon']) : city.longitude,
      measuredAt: DateTime.fromMillisecondsSinceEpoch(
        _toInt(json['dt']) * 1000,
        isUtc: true,
      ).toLocal(),
    );
  }

  /// Icone officielle OpenWeatherMap (aucune cle necessaire pour l'image).
  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  String get temperatureLabel => '${temperature.round()} °C';
  String get feelsLikeLabel => '${feelsLike.round()} °C';
  String get minMaxLabel =>
      '${temperatureMin.round()} °C / ${temperatureMax.round()} °C';
  String get humidityLabel => '$humidity %';
  String get pressureLabel => '$pressure hPa';
  String get cloudinessLabel => '$cloudiness %';

  /// Vitesse convertie en km/h, plus parlante que les m/s de l'API.
  String get windLabel =>
      '${(windSpeed * 3.6).toStringAsFixed(1)} km/h $windDirectionLabel';

  /// Coordonnees formatees facon geomatique (5 decimales ~ 1 m de precision).
  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  /// Description avec une majuscule initiale, pour l'affichage.
  String get formattedDescription => description.isEmpty
      ? description
      : '${description[0].toUpperCase()}${description.substring(1)}';

  /// Heure de la mesure au format HH:mm (sans dependance a intl).
  String get measuredAtLabel {
    final String hh = measuredAt.hour.toString().padLeft(2, '0');
    final String mm = measuredAt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Convertit la direction du vent en rose des vents a 8 secteurs.
  String get windDirectionLabel {
    const List<String> sectors = <String>[
      'Nord',
      'Nord-Est',
      'Est',
      'Sud-Est',
      'Sud',
      'Sud-Ouest',
      'Ouest',
      'Nord-Ouest',
    ];
    // Chaque secteur couvre 45 deg ; on decale de 22.5 deg pour centrer le nord.
    final int index = (((windDegree % 360) + 22.5) ~/ 45) % 8;
    return '(${sectors[index]})';
  }

  static double _toDouble(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static int _toInt(Object? value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;
}