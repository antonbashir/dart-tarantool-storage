import 'dart:io';

import 'package:linux_interactor/linux_interactor.dart';

void main() {
  final command = (
    executable: "dart",
    args: [
      "run",
      "ffigen",
      "--compiler-opts",
      "-I/${File(InteractorLibrary.load().path).parent.path}/../../native/include",
    ]
  );
  final result = Process.runSync(command.executable, command.args);
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    throw Exception(command);
  }
  final file = File("lib/storage/bindings.dart");
  var content = file.readAsStringSync();
  content = content.replaceAll(
    "// ignore_for_file: type=lint",
    "// ignore_for_file: type=lint, unused_field",
  );
  file.writeAsStringSync(content);
}
