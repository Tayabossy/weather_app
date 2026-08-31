/// Etat generique d'une requete reseau.
///
/// On utilise une `sealed class` (Dart 3) plutot qu'un simple booleen :
/// le compilateur verifie alors l'exhaustivite des `switch` cote interface,
/// il est donc impossible d'oublier de gerer le cas d'erreur.
sealed class RequestState<T> {
  const RequestState();

  /// La requete n'a pas encore ete lancee.
  bool get isIdle => this is RequestIdle<T>;

  /// La requete est en cours.
  bool get isLoading => this is RequestLoading<T>;

  /// La requete est terminee, avec succes ou en erreur.
  bool get isTerminal => this is RequestSuccess<T> || this is RequestFailure<T>;

  /// Donnee utile si la requete a reussi, `null` sinon.
  T? get dataOrNull => switch (this) {
        RequestSuccess<T>(:final data) => data,
        _ => null,
      };
}

/// Etat initial : rien n'a encore ete demande au serveur.
final class RequestIdle<T> extends RequestState<T> {
  const RequestIdle();
}

/// Chargement en cours.
final class RequestLoading<T> extends RequestState<T> {
  const RequestLoading();
}

/// Succes : les donnees sont disponibles.
final class RequestSuccess<T> extends RequestState<T> {
  const RequestSuccess(this.data);

  final T data;
}

/// Echec : message deja traduit, pret a etre affiche a l'utilisateur.
final class RequestFailure<T> extends RequestState<T> {
  const RequestFailure(this.message, {this.isRetryable = true});

  /// Message clair en francais (jamais la stack trace brute de Dio).
  final String message;

  /// `false` pour les erreurs de configuration (cle API absente par exemple),
  /// que relancer a l'identique ne resoudrait pas.
  final bool isRetryable;
}