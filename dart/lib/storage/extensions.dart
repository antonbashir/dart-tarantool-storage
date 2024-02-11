import 'constants.dart';

extension StringExtensions on String {
  get quoted => "'$this'";
}

extension UpdateOperationTypeExtension on StorageUpdateOperationType {
  String operation() {
    switch (this) {
      case StorageUpdateOperationType.add:
        return "+";
      case StorageUpdateOperationType.subtract:
        return "-";
      case StorageUpdateOperationType.bitwiseAnd:
        return "&";
      case StorageUpdateOperationType.bitwiseOr:
        return "|";
      case StorageUpdateOperationType.bitwiseXor:
        return "^";
      case StorageUpdateOperationType.stringSplice:
        return ":";
      case StorageUpdateOperationType.insert:
        return "!";
      case StorageUpdateOperationType.delete:
        return "#";
      case StorageUpdateOperationType.assign:
        return "=";
    }
  }
}