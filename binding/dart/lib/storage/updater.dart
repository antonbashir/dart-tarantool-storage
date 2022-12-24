import 'constants.dart';

class UpdateOperation {
  final UpdateOperationType type;
  final int field;
  final dynamic value;

  UpdateOperation(this.type, this.field, this.value);
}
