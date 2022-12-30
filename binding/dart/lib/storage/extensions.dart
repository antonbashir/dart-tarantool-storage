import 'constants.dart';

extension StringExtensions on String {
  get quotted => "'$this'";
}

extension UpdateOperationTypeExtension on UpdateOperationType {
  String operation() {
    switch (this) {
      case UpdateOperationType.add:
        return "+";
      case UpdateOperationType.subtract:
        return "-";
      case UpdateOperationType.bitwiseAnd:
        return "&";
      case UpdateOperationType.bitwiseOr:
        return "|";
      case UpdateOperationType.bitwiseXor:
        return "^";
      case UpdateOperationType.stringSplice:
        return ":";
      case UpdateOperationType.insert:
        return "!";
      case UpdateOperationType.delete:
        return "#";
      case UpdateOperationType.assign:
        return "=";
    }
  }
}
