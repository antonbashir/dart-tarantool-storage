import 'dart:io';

import 'package:path/path.dart';
import 'package:tar/tar.dart';
import 'package:tarantool_storage/storage/constants.dart';
import 'package:tarantool_storage/storage/lookup.dart';

import 'compile.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print(Messages.specifyDartEntryPoint);
    exit(1);
  }
  final root = Directory.current.uri;
  final entryPoint = File(args[0]);
  if (!entryPoint.existsSync()) {
    print(Messages.specifyDartEntryPoint);
    exit(1);
  }
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
  final packageNativeRoot = Directory(packageRoot.toFilePath() + Directories.native);
  final resultPackageRoot = Directory(root.toFilePath() + Directories.package);
  if (resultPackageRoot.existsSync()) resultPackageRoot.deleteSync(recursive: true);
  final nativeRoot = Directory(root.toFilePath() + Directories.native);
  final luaRoot = Directory(root.toFilePath() + Directories.lua);
  if (!resultPackageRoot.existsSync()) resultPackageRoot.createSync();
  if (luaRoot.existsSync()) copyLua(luaRoot, resultPackageRoot);
  compileDart(resultPackageRoot, entryPoint);
  copyLibrary(packageNativeRoot, resultPackageRoot);
  compileNative(nativeRoot, projectName);
  if (nativeRoot.existsSync()) copyNative(nativeRoot, projectName, resultPackageRoot);
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
        star,
      ],
      runInShell: true,
      workingDirectory: resultPackageRoot.path);
  if (compile.exitCode != 0) {
    print(compile.stderr.toString());
    exit(compile.exitCode);
  }
}
