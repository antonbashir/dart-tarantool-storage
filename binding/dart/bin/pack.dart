import 'dart:io';

import 'package:path/path.dart';
import '../lib/storage/constants.dart';
import '../lib/storage/lookup.dart';

import 'compile.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print(Messages.specifyDartEntryPoint);
    exit(1);
  }
  final root = Directory.current.uri;
  final entryPoint = File(arguments[0]);
  if (!entryPoint.existsSync()) {
    print(Messages.specifyDartEntryPoint);
    exit(1);
  }
  bool native = (arguments.length > 1 && arguments[1] == Arguments.native) || (arguments.length > 2 && arguments[2] == Arguments.native);
  bool lua = (arguments.length > 1 && arguments[1] == Arguments.lua) || (arguments.length > 2 && arguments[2] == Arguments.lua);
  final dotDartTool = findDotDartTool();
  if (dotDartTool == null) {
    print(Messages.runPubGet);
    exit(1);
  }
  final projectRoot = findProjectRoot();
  if (projectRoot == null) {
    print(Messages.projectRootNotFound);
    exit(1);
  }
  final projectName = basename(projectRoot);
  final packageRoot = findPackageRoot(dotDartTool);
  final resultPackageRoot = Directory(root.toFilePath() + Directories.package);
  if (resultPackageRoot.existsSync()) resultPackageRoot.deleteSync(recursive: true);
  if (native) {
    final packageNativeRoot = Directory(packageRoot.toFilePath() + Directories.native);
    final nativeRoot = Directory(root.toFilePath() + Directories.native);
    if (!resultPackageRoot.existsSync()) resultPackageRoot.createSync();
    copyLibrary(packageNativeRoot, resultPackageRoot);
    compileNative(nativeRoot, packageNativeRoot, projectName);
    if (nativeRoot.existsSync()) copyNative(nativeRoot, projectName, resultPackageRoot);
  }
  if (lua) {
    final luaRoot = Directory(root.toFilePath() + Directories.lua);
    if (luaRoot.existsSync()) copyLua(luaRoot, resultPackageRoot);
  }
  compileDart(resultPackageRoot, entryPoint);
  archive(resultPackageRoot, projectName);
  resultPackageRoot.deleteSync(recursive: true);
}

void copyLibrary(Directory packageNativeRoot, Directory resultPackageRoot) {
  File(packageNativeRoot.path + slash + storageLibraryName).copySync(resultPackageRoot.path + slash + storageLibraryName);
}

void copyNative(Directory nativeRoot, String projectName, Directory resultPackageRoot) {
  File(nativeRoot.path + slash + projectName + dot + FileExtensions.so).copySync(resultPackageRoot.path + slash + projectName + dot + FileExtensions.so);
}

void copyLua(Directory luaRoot, Directory resultPackageRoot) {
  luaRoot.listSync(recursive: true).whereType<File>().forEach((element) => element.copySync(resultPackageRoot.path + slash + basename(element.path)));
}

void compileDart(Directory resultPackageRoot, File entryPoint) {
  final compile = Process.runSync(
    CompileOptions.dartExecutable,
    [
      CompileOptions.compileCommand,
      FileExtensions.exe,
      entryPoint.path,
      CompileOptions.outputOption,
      resultPackageRoot.path + slash + basenameWithoutExtension(entryPoint.path) + dot + FileExtensions.exe,
    ],
    runInShell: true,
  );
  if (compile.exitCode != 0) {
    print(compile.stderr.toString());
    exit(compile.exitCode);
  }
}

Future<void> archive(Directory resultPackageRoot, String projectName) async {
  final archiveFile = File(projectName + dot + FileExtensions.tarGz);
  if (archiveFile.existsSync()) archiveFile.deleteSync();
  final compile = Process.runSync(
      CompileOptions.tarExecutable,
      [
        CompileOptions.tarOption,
        resultPackageRoot.parent.path + slash + projectName + dot + FileExtensions.tarGz,
        currentDirectorySymbol,
      ],
      runInShell: true,
      workingDirectory: resultPackageRoot.path);
  if (compile.exitCode != 0) {
    print(compile.stderr.toString());
    exit(compile.exitCode);
  }
}
