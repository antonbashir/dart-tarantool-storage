import 'dart:io';

import 'package:path/path.dart';
import 'package:tarantool_storage/storage/constants.dart';
import 'package:tarantool_storage/storage/lookup.dart';

Future<void> main(List<String> args) async {
  final root = Directory.current.uri;
  final projectRoot = findProjectRoot();
  if (projectRoot == null) {
    print(Messages.projectRootNotFound);
    exit(1);
  }
  final projectName = basename(projectRoot);
  final nativeRoot = Directory(root.toFilePath() + Directories.native);
  if (!nativeRoot.existsSync()) {
    exit(1);
  }
  compileNative(nativeRoot, projectName);
}

void compileNative(Directory nativeRoot, String projectName) {
  final compile = Process.runSync(
    CompileOptions.gccExecutable,
    [
      CompileOptions.gccSharedOption,
      CompileOptions.gccSharedOption,
      CompileOptions.outputOption,
      nativeRoot.path + slash + projectName + dot + FileExtensions.so,
      ...nativeRoot.listSync().map((file) => file.path).toList()
    ],
    runInShell: true,
  );
  if (compile.exitCode != 0) {
    print(compile.stderr.toString());
    exit(compile.exitCode);
  }
}
