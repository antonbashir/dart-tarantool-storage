class StorageRequestsLimitException implements Exception {}

class StorageShutdownException implements Exception {}

class StorageExecutionException implements Exception {
  final String _error;

  StorageExecutionException(this._error);

  @override
  String toString() => _error;
}
