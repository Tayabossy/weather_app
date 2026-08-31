/// Represente une ville interrogeable par l'application.
///
/// Les coordonnees sont stockees dans le modele pour deux raisons :
///  1. l'appel API se fait par latitude/longitude (plus fiable qu'une
///     recherche par nom, qui peut etre ambigue) ;
///  2. l'ecran de detail affiche directement le marqueur sur la carte,
///     meme si la reponse reseau n'est pas encore arrivee.
class City {
  const City({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  /// Identifiant interne stable (sert de cle dans les maps du provider).
  final String id;

  /// Nom affiche dans le tableau et sur la carte.
  final String name;

  /// Code pays ISO 3166 (ex : SN pour le Senegal).
  final String country;

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is City && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'City($id)';
}

/// Les cinq villes suivies par l'experience meteo.
///
/// Le sujet laisse le choix des villes : nous retenons un panel senegalais
/// pertinent pour un cursus de geomatique a l'UIDT de Thies, reparti sur
/// l'ensemble du territoire (littoral, nord, sud, est).
const List<City> defaultCities = <City>[
  City(
    id: 'dakar',
    name: 'Dakar',
    country: 'SN',
    latitude: 14.6928,
    longitude: -17.4467,
  ),
  City(
    id: 'thies',
    name: 'Thies',
    country: 'SN',
    latitude: 14.7886,
    longitude: -16.9260,
  ),
  City(
    id: 'saint-louis',
    name: 'Saint-Louis',
    country: 'SN',
    latitude: 16.0179,
    longitude: -16.4896,
  ),
  City(
    id: 'ziguinchor',
    name: 'Ziguinchor',
    country: 'SN',
    latitude: 12.5681,
    longitude: -16.2719,
  ),
  City(
    id: 'tambacounda',
    name: 'Tambacounda',
    country: 'SN',
    latitude: 13.7708,
    longitude: -13.6673,
  ),
];