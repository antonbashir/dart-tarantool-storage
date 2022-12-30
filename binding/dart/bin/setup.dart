import 'dart:io';

import 'package:path/path.dart';
import '../lib/storage/constants.dart';
import '../lib/storage/lookup.dart';

void main() {
  final root = Directory.current.uri;
  final dotDartTool = findDotDartTool();
  if (dotDartTool == null) {
    print(Messages.runPubGet);
    exit(1);
  }
  final packageRoot = findPackageRoot(dotDartTool);
  final packageNativeRoot = Directory(packageRoot.toFilePath() + Directories.native);
  final nativeRoot = Directory(root.toFilePath() + Directories.native);
  if (!nativeRoot.existsSync()) nativeRoot.createSync();
  final packageLuaRoot = Directory(packageRoot.toFilePath() + Directories.lua);
  final luaRoot = Directory(root.toFilePath() + Directories.lua);
  if (!luaRoot.existsSync()) luaRoot.createSync();
  copyHeaders(packageNativeRoot, nativeRoot);
  copyLuaScrits(packageLuaRoot, luaRoot);
}

void copyHeaders(Directory packageNativeRoot, Directory nativeRoot) {
  packageNativeRoot
      .listSync()
      .whereType<File>()
      .where((element) => extension(element.path) == dot + FileExtensions.h)
      .forEach((element) => element.copySync(nativeRoot.path + slash + basename(element.path)));
}

void copyLuaScrits(Directory packageLuaRoot, Directory luaRoot) {
  packageLuaRoot
      .listSync()
      .whereType<File>()
      .where((element) => extension(element.path) == dot + FileExtensions.lua)
      .forEach((element) => element.copySync(luaRoot.path + slash + basename(element.path)));
}
