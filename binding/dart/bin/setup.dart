import 'dart:io';

import 'package:path/path.dart';
import '../lib/storage/constants.dart';
import '../lib/storage/lookup.dart';

void main(List<String> arguments) {
  bool native = (arguments.length > 0 && arguments[0] == Arguments.native) || (arguments.length > 1 && arguments[1] == Arguments.native);
  bool lua = (arguments.length > 0 && arguments[0] == Arguments.lua) || (arguments.length > 1 && arguments[1] == Arguments.lua);
  final root = Directory.current.uri;
  final dotDartTool = findDotDartTool();
  if (dotDartTool == null) {
    print(Messages.runPubGet);
    exit(1);
  }
  final packageRoot = findPackageRoot(dotDartTool);
  if (native) {
    final packageNativeRoot = Directory(packageRoot.toFilePath() + Directories.native);
    final nativeRoot = Directory(root.toFilePath() + Directories.native);
    if (!nativeRoot.existsSync()) nativeRoot.createSync();
    copyHeaders(packageNativeRoot, nativeRoot);
  }
  if (lua) {
    final packageLuaRoot = Directory(packageRoot.toFilePath() + Directories.lua);
    final luaRoot = Directory(root.toFilePath() + Directories.lua);
    if (!luaRoot.existsSync()) luaRoot.createSync();
    copyLuaScrits(packageLuaRoot, luaRoot);
  }
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
