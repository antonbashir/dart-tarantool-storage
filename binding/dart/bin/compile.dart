import 'dart:io';

import 'package:path/path.dart';
import '../lib/storage/constants.dart';
import '../lib/storage/lookup.dart';

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
    print(Messages.nativeDirectoryNotFound);
    exit(1);
  }
  if (!nativeRoot.listSync().any((element) => element is File && (element.path.endsWith(dot + FileExtensions.c) || element.path.endsWith(dot + FileExtensions.cpp)))) {
    print(Messages.nativeSourcesNotFound);
    exit(1);
  }
  final dotDartTool = findDotDartTool();
  if (dotDartTool == null) {
    print(Messages.runPubGet);
    exit(1);
  }
  final packageRoot = findPackageRoot(dotDartTool);
  final packageNativeRoot = Directory(packageRoot.toFilePath() + Directories.native);
  compileNative(nativeRoot, packageNativeRoot, projectName);
}

void compileNative(Directory nativeRoot, Directory packageNativeRoot, String projectName) {
  final resultLibrary = File(nativeRoot.path + slash + projectName + dot + FileExtensions.so);
  if (resultLibrary.existsSync()) resultLibrary.deleteSync();
  final compile = Process.runSync(
    CompileOptions.gccExecutable,
    [
      CompileOptions.gccSharedOption,
      "-rdynamic",
      CompileOptions.gccFpicOption,
      "-L${packageNativeRoot.path}/$storageLibraryName}",
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
