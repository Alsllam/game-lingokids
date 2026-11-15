/// Typed errors returned by repositories and use cases.
///
/// The UI decides how to show them; a failure never carries widgets or
/// localized text.
sealed class Failure {
  const Failure(this.message);

  /// Technical detail for logs. Not shown to children.
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// The bundled content file is missing or malformed.
final class ContentFailure extends Failure {
  const ContentFailure(super.message);
}

/// Something asked for by id does not exist in the catalog.
final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Reading or writing local storage failed.
final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}
