import '../constants.dart';

class StorageUpdateOperation {
  final StorageUpdateOperationType type;
  final int field;
  final dynamic value;

  const StorageUpdateOperation._(this.type, this.field, this.value);

  factory StorageUpdateOperation.add(int field, dynamic value) => StorageUpdateOperation._(StorageUpdateOperationType.add, field, value);
  factory StorageUpdateOperation.subtract(int field, dynamic value) => StorageUpdateOperation._(StorageUpdateOperationType.subtract, field, value);
  factory StorageUpdateOperation.bitwiseAnd(int field, dynamic value) => StorageUpdateOperation._(StorageUpdateOperationType.bitwiseAnd, field, value);
  factory StorageUpdateOperation.bitwiseOr(int field, dynamic value) => StorageUpdateOperation._(StorageUpdateOperationType.bitwiseOr, field, value);
  factory StorageUpdateOperation.bitwiseXor(int field, dynamic value) => StorageUpdateOperation._(StorageUpdateOperationType.bitwiseXor, field, value);
  factory StorageUpdateOperation.stringSplice(int field, dynamic value) => StorageUpdateOperation._(StorageUpdateOperationType.stringSplice, field, value);
  factory StorageUpdateOperation.insert(int field, dynamic value) => StorageUpdateOperation._(StorageUpdateOperationType.insert, field, value);
  factory StorageUpdateOperation.delete(int field, dynamic value) => StorageUpdateOperation._(StorageUpdateOperationType.delete, field, value);
  factory StorageUpdateOperation.assign(int field, dynamic value) => StorageUpdateOperation._(StorageUpdateOperationType.assign, field, value);
}
