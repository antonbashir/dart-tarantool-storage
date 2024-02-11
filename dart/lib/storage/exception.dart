class StorageLimitException implements Exception {}

class StorageLauncherException implements Exception {
  final String _error;

  const StorageLauncherException(this._error);

  @override
  String toString() => _error;
}

class StorageExecutionException implements Exception {
  final String _error;

  const StorageExecutionException(this._error);

  @override
  String toString() => _error;
}
