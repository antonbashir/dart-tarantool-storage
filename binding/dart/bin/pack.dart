import 'dart:io';

import 'package:path/path.dart';
import 'package:tar/tar.dart';
import 'package:tarantool_storage/storage/constants.dart';
import 'package:tarantool_storage/storage/lookup.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Specify dart execution entry point');
    exit(1);
  }
  final root = Directory.current.uri;
  final entryPoint = File(args[0]);
  if (!entryPoint.existsSync()) {
    print('Specify dart execution entry point');
    exit(1);
  }
  final dotDartTool = findDotDartTool();
  if (dotDartTool == null) {
    print("Run 'dart pub get'");
    exit(1);
  }
  final packageRoot = findPackageRoot(dotDartTool);
  final packageNativeRoot = Directory(packageRoot.toFilePath() + nativeDirectory);
  final moduleRoot = Directory(root.toFilePath() + moduleDirectory);
  final nativeRoot = Directory(root.toFilePath() + nativeDirectory);
  final luaRoot = Directory(root.toFilePath() + luaDirectory);
  if (!moduleRoot.existsSync()) moduleRoot.createSync();
  if (nativeRoot.existsSync()) copyNative(nativeRoot, moduleRoot);
  if (luaRoot.existsSync()) copyLua(luaRoot, moduleRoot);
  copyLibrary(packageNativeRoot, moduleRoot);
  compile(moduleRoot, entryPoint);
  archive(moduleRoot);
}

void copyLibrary(Directory packageNativeRoot, Directory moduleRoot) {
  File(packageNativeRoot.path + slash + storageLibraryName).copySync(moduleRoot.path + slash + storageLibraryName);
}

void copyNative(Directory nativeRoot, Directory moduleRoot) {
  nativeRoot.listSync(recursive: true).whereType<File>().forEach((element) => element.copySync(moduleRoot.path + slash + basename(element.path)));
}

void copyLua(Directory luaRoot, Directory moduleRoot) {
  luaRoot.listSync(recursive: true).whereType<File>().forEach((element) => element.copySync(moduleRoot.path + slash + basename(element.path)));
}

void compile(Directory moduleRoot, File entryPoint) {
  final compile = Process.runSync(
    'dart',
    [
      'compile',
      FileExtensions.exe,
      entryPoint.path,
      "-o",
      moduleRoot.path + slash + basenameWithoutExtension(entryPoint.path) + dot + FileExtensions.exe,
    ],
    runInShell: true,
  );
  if (compile.exitCode != 0) {
    print(compile.stderr.toString());
    exit(compile.exitCode);
  }
}

Future<void> archive(Directory moduleRoot) async {
  final tarEntries = Stream<TarEntry>.fromIterable(
    moduleRoot.listSync().whereType<File>().map((file) => TarEntry.data(TarHeader(name: basename(file.path)), file.readAsBytesSync())),
  );
  await tarEntries.transform(tarWriter).transform(gzip.encoder).pipe(File(moduleArchivFile).openWrite());
}
