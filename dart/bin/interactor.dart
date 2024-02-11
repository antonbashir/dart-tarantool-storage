import 'dart:io';

import 'package:linux_interactor/linux_interactor.dart' deferred as linux_interactor
    hide
        InteractorMessageExtensions,
        InteractorTupleIntExtension,
        InteractorTupleMapExtension,
        InteractorTupleListExtension,
        InteractorTupleBinaryExtension,
        InteractorTupleDoubleExtension,
        InteractorTupleStringExtension,
        InteractorTupleBooleanExtension;

void main() {
  Process.runSync("dart", ["pub", "get"], workingDirectory: Directory.current.parent.path);
  print(linux_interactor.InteractorLibrary.load().path);
}
