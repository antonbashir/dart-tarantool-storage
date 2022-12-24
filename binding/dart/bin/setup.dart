import 'dart:io';

import 'package:path/path.dart';
import 'package:tarantool_storage/storage/constants.dart';
import 'package:tarantool_storage/storage/lookup.dart';

void main() {
  final root = Directory.current.uri;
  final dotDartTool = findDotDartTool();
  if (dotDartTool == null) {
    print("Run 'dart pub get'");
    exit(1);
  }
  final packageRoot = findPackageRoot(dotDartTool);
  final packageNativeRoot = Directory(packageRoot.toFilePath() + nativeDirectory);
  final nativeRoot = Directory(root.toFilePath() + nativeDirectory);
  if (!nativeRoot.existsSync()) nativeRoot.createSync();
  final packageLuaRoot = Directory(packageRoot.toFilePath() + luaDirectory);
  final luaRoot = Directory(root.toFilePath() + luaDirectory);
  if (!luaRoot.existsSync()) luaRoot.createSync();
  copyHeaders(packageNativeRoot, nativeRoot);
  copyLuaScrits(packageLuaRoot, luaRoot);
}

void copyHeaders(Directory packageNativeRoot, Directory nativeRoot) {
  packageNativeRoot
      .listSync()
      .whereType<File>()
      .where((element) => extension(element.path) == dot + headerExtension)
      .forEach((element) => element.copySync(nativeRoot.path + slash + basename(element.path)));
}

void copyLuaScrits(Directory packageNativeRoot, Directory packageLuaRoot) {
  packageLuaRoot
      .listSync()
      .whereType<File>()
      .where((element) => extension(element.path) == dot + luaExtension)
      .forEach((element) => element.copySync(packageLuaRoot.path + slash + basename(element.path)));
}
