import '../constants.dart';

class StorageUpdateOperation {
  final UpdateOperationType type;
  final int field;
  final dynamic value;

  const StorageUpdateOperation._(this.type, this.field, this.value);

  factory StorageUpdateOperation.add(int field, dynamic value) => StorageUpdateOperation._(UpdateOperationType.add, field, value);
  factory StorageUpdateOperation.subtract(int field, dynamic value) => StorageUpdateOperation._(UpdateOperationType.subtract, field, value);
  factory StorageUpdateOperation.bitwiseAnd(int field, dynamic value) => StorageUpdateOperation._(UpdateOperationType.bitwiseAnd, field, value);
  factory StorageUpdateOperation.bitwiseOr(int field, dynamic value) => StorageUpdateOperation._(UpdateOperationType.bitwiseOr, field, value);
  factory StorageUpdateOperation.bitwiseXor(int field, dynamic value) => StorageUpdateOperation._(UpdateOperationType.bitwiseXor, field, value);
  factory StorageUpdateOperation.stringSplice(int field, dynamic value) => StorageUpdateOperation._(UpdateOperationType.stringSplice, field, value);
  factory StorageUpdateOperation.insert(int field, dynamic value) => StorageUpdateOperation._(UpdateOperationType.insert, field, value);
  factory StorageUpdateOperation.delete(int field, dynamic value) => StorageUpdateOperation._(UpdateOperationType.delete, field, value);
  factory StorageUpdateOperation.assign(int field, dynamic value) => StorageUpdateOperation._(UpdateOperationType.assign, field, value);
}
