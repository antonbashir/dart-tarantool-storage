import 'dart:io';
import 'dart:math';

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
  final resultLibrary = File(nativeRoot.path + slash + projectName + dot + FileExtensions.so);
  if (resultLibrary.existsSync()) resultLibrary.deleteSync();
  final compile = Process.runSync(
    CompileOptions.gccExecutable,
    [
      CompileOptions.gccSharedOption,
      CompileOptions.gccFpicOption,
      CompileOptions.outputOption,
      resultLibrary.path,
      ...nativeRoot
          .listSync()
          .whereType<File>()
          .where((file) => [dot + FileExtensions.c, dot + FileExtensions.h, dot + FileExtensions.hpp, dot + FileExtensions.cpp].contains(extension(file.path)))
          .map((file) => file.path)
          .toList(),
    ],
    runInShell: true,
  );
  if (compile.exitCode != 0) {
    print(compile.stderr.toString());
    exit(compile.exitCode);
  }
}
