# WeatherApp — Examen de Développement Mobile

Application Flutter réalisée dans le cadre de l'examen de **Développement
Mobile**, Licence 3 Géomatique — **UIDT, 2026**, fait par Mouhamet Oumar Sissokho Sy et Fatou Taye Ndiaye.

L'application récupère en direct la météo de **cinq villes du Sénégal** auprès
de l'API [OpenWeatherMap](https://openweathermap.org/current), présente les
relevés dans un tableau interactif, puis localise chaque ville sur une **carte
OpenStreetMap** via `flutter_map`.

## Fonctionnalités

| # | Fonctionnalité | Détail |
|---|----------------|--------|
| 1 | **Écran d'accueil** | Présentation de l'application et bouton « Démarrer l'expérience ». |
| 2 | **Jauge animée** | Une jauge circulaire (`percent_indicator`) se remplit sur 9 s, pilotée par un `Timer.periodic` de 100 ms. |
| 3 | **Appels échelonnés** | Les 5 villes sont interrogées successivement (une requête toutes les 1,5 s) pendant le remplissage. |
| 4 | **Messages d'attente** | Une liste de messages défile en boucle toutes les 1,8 s, avec une transition animée. |
| 5 | **Tableau interactif** | Affiché quand la jauge atteint 100 % **et** que les 5 villes ont répondu : ville, température, description, icône. |
| 6 | **Bouton « Recommencer »** | La jauge se transforme en bouton qui réinitialise tout l'état et relance l'expérience de zéro. |
| 7 | **Écran de détail** | Température, ressenti, humidité, vent, pression, nuages, min/max + carte interactive avec marqueur. |
| 8 | **Gestion des erreurs** | Chaque erreur réseau (timeout, hors ligne, 401, 404, 429, 5xx) devient un message clair, avec un bouton « Réessayer » qui **ne relance que la requête échouée**. |
| 9 | **Mode clair / sombre** | Deux `ThemeData` Material 3, bascule depuis l'AppBar, choix persisté avec `shared_preferences`. |
| 10 | **Navigation** | Routes nommées, bouton retour natif Android et bouton « Accueil » depuis l'écran de détail. |
| 11 | **Interface animée** | Fond vivant (halos dérivants + nuages), entrées en cascade, transitions de pages personnalisées, animation `Hero` entre le tableau et la fiche détail, températures qui défilent. |

### Détail des animations

| Animation | Où | Mise en œuvre |
|-----------|-----|---------------|
| Fond « aurore » | Les 3 écrans | `AnimatedBackground` : halos radiaux peints au `CustomPaint`, cycle de 24 s |
| Nuages dérivants | Accueil | Traversée de l'écran en boucle, 3 nuages déphasés |
| Logo vivant | Accueil | Soleil en rotation continue + nuage qui oscille (1 seul `AnimationController`) |
| Bouton pulsant | Accueil | `ScaleTransition` en boucle, amplitude 3 % |
| Entrées en cascade | Partout | `FadeSlideIn` avec un `delay` croissant |
| Halo + couronne | Jauge | Halo qui « respire » et 24 points en rotation avec traînée |
| Compteur de température | Tableau | `TweenAnimationBuilder` de 0 à la valeur réelle |
| Vol de l'icône | Tableau → détail | `Hero` avec le tag `weather-icon-<id>` |
| Transitions de pages | Navigation | `PageRouteBuilder` : fondu + remontée douce |

### Villes suivies

Dakar, Thiès, Saint-Louis, Ziguinchor et Tambacounda — un panel réparti sur
l'ensemble du territoire (littoral, nord, sud, est), pertinent pour un cursus
de géomatique. Elles sont définies dans `lib/models/city.dart` et se modifient
en une ligne.

## Installation et lancement

### 1. Prérequis

- Flutter SDK stable (développé et testé avec **Flutter 3.44.1 / Dart 3.12.1**)
- Un émulateur Android, un appareil physique, ou un navigateur Chrome

Vérifiez votre installation :

```bash
flutter doctor
```

### 2. Récupérer les dépendances

```bash
flutter pub get
```

### 3. Configurer la clé API

L'application a besoin d'une clé OpenWeatherMap (gratuite).

1. Créez un compte sur <https://home.openweathermap.org/users/sign_up>
2. Copiez votre clé depuis l'onglet **My API keys**
3. Créez le fichier `.env` à partir du modèle fourni :

```bash
# Windows
copy .env.example .env

# Linux / macOS
cp .env.example .env
```

4. Ouvrez `.env` et remplacez `your_key_here` par votre clé :

```env
OPENWEATHER_API_KEY=votre_cle_ici
```

> ⚠️ Une clé fraîchement créée peut mettre **jusqu'à 2 heures** avant d'être
> activée par OpenWeatherMap ; en attendant, l'API répond `401` et
> l'application affiche le message d'erreur correspondant.

> 🔒 Le fichier `.env` est ignoré par git (voir `.gitignore`) : seule sa
> version modèle `.env.example` est versionnée. Ne committez jamais votre clé.

> 📌 Cette étape n'est pas optionnelle : `.env` est déclaré comme *asset* dans
> `pubspec.yaml`, la compilation échoue donc si le fichier est absent. S'il
> existe mais contient encore `your_key_here`, l'application démarre et affiche
> un message d'erreur explicite dans le tableau.

### 4. Lancer l'application

```bash
flutter run
```

### 5. Vérifications

```bash
flutter analyze   # analyse statique : 0 erreur attendue
flutter test      # tests unitaires et widget
```

## Architecture du projet

```text
lib/
├── main.dart                       # Point d'entrée : dotenv, providers, thèmes
├── app_routes.dart                 # Routes nommées (onGenerateRoute typé)
│
├── models/
│   ├── city.dart                   # Ville + catalogue des 5 villes
│   ├── weather_model.dart          # Données météo (parsing du JSON OWM)
│   └── request_state.dart          # sealed class Idle / Loading / Success / Failure
│
├── services/
│   └── weather_service.dart        # Appels dio + traduction des erreurs
│
├── providers/
│   ├── theme_provider.dart         # Mode clair/sombre + persistance
│   └── weather_provider.dart       # Jauge, timers, appels, états par ville
│
├── screens/
│   ├── home_screen.dart            # Accueil
│   ├── weather_screen.dart         # Jauge → tableau de résultats
│   └── weather_detail_screen.dart  # Détails + carte OpenStreetMap
│
├── widgets/
│   ├── animated_background.dart    # Fond animé (halos + nuages dérivants)
│   ├── fade_slide_in.dart          # Animation d'entrée réutilisable (cascade)
│   ├── weather_gauge.dart          # Jauge circulaire animée
│   ├── weather_city_card.dart      # Ligne du tableau (4 états possibles)
│   ├── weather_icon.dart           # Icône OWM + repli hors ligne
│   ├── error_message.dart          # Message d'erreur + « Réessayer »
│   ├── weather_map.dart            # Carte flutter_map + marqueur
│   ├── info_tile.dart              # Tuile « libellé / valeur »
│   └── theme_toggle_button.dart    # Bascule clair / sombre
│
└── theme/
    └── app_theme.dart              # ThemeData clair et sombre
```

### Choix techniques

- **`dio`** pour le réseau : timeouts explicites (10 s) et types d'erreurs
  détaillés (`connectionError`, `receiveTimeout`…), traduits en messages
  français dans `WeatherService`. Le reste de l'application ne manipule jamais
  une `DioException`.
- **`provider`** pour l'état : deux `ChangeNotifier` seulement, ce qui reste
  lisible pour un projet d'examen. `WeatherProvider` orchestre les trois timers
  (jauge, messages, requêtes) et expose un état par ville.
- **`sealed class RequestState`** : le compilateur vérifie l'exhaustivité des
  `switch` dans l'interface, donc le cas d'erreur ne peut pas être oublié.
- **`flutter_map` + OpenStreetMap** : cartographie gratuite, sans clé d'API et
  sans compte Google Cloud, contrairement à Google Maps.
- **Identifiant de cycle (`_runId`)** : une réponse réseau tardive appartenant
  à une exécution précédente est ignorée après un « Recommencer », ce qui évite
  d'afficher des données périmées.
- **Requêtes par latitude/longitude** plutôt que par nom de ville : plus fiable
  (aucune ambiguïté entre communes homonymes) et directement réutilisable pour
  centrer la carte.

## Dépendances

| Package | Rôle |
|---------|------|
| `dio` | Appels HTTP vers OpenWeatherMap |
| `provider` | Gestion d'état globale |
| `flutter_map` + `latlong2` | Carte interactive OpenStreetMap |
| `flutter_dotenv` | Chargement de la clé API depuis `.env` |
| `shared_preferences` | Persistance du mode clair/sombre |
| `percent_indicator` | Jauge circulaire animée |
| `flutter_localizations` | Libellés système en français |

## Crédits

- Données météo : [OpenWeatherMap](https://openweathermap.org/)
- Fonds de carte : © [OpenStreetMap](https://www.openstreetmap.org/copyright)
  contributors (licence ODbL)

## Membres du groupe

- Fatou Taye NDIAYE
- Mouhamet Oumar Sissokho SY