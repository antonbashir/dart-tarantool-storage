import 'constants.dart';

class UpdateOperation {
  final UpdateOperationType type;
  final int field;
  final dynamic value;

  const UpdateOperation._(this.type, this.field, this.value);

  factory UpdateOperation.add(int field, dynamic value) => UpdateOperation._(UpdateOperationType.add, field, value);
  factory UpdateOperation.subtract(int field, dynamic value) => UpdateOperation._(UpdateOperationType.subtract, field, value);
  factory UpdateOperation.bitwiseAnd(int field, dynamic value) => UpdateOperation._(UpdateOperationType.bitwiseAnd, field, value);
  factory UpdateOperation.bitwiseOr(int field, dynamic value) => UpdateOperation._(UpdateOperationType.bitwiseOr, field, value);
  factory UpdateOperation.bitwiseXor(int field, dynamic value) => UpdateOperation._(UpdateOperationType.bitwiseXor, field, value);
  factory UpdateOperation.stringSplice(int field, dynamic value) => UpdateOperation._(UpdateOperationType.stringSplice, field, value);
  factory UpdateOperation.insert(int field, dynamic value) => UpdateOperation._(UpdateOperationType.insert, field, value);
  factory UpdateOperation.delete(int field, dynamic value) => UpdateOperation._(UpdateOperationType.delete, field, value);
  factory UpdateOperation.assign(int field, dynamic value) => UpdateOperation._(UpdateOperationType.assign, field, value);
}
