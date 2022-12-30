import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform, Directory, File;

import 'constants.dart';

DynamicLibrary loadBindingLibrary() {
  try {
    return Platform.isLinux ? DynamicLibrary.open(storageLibraryName) : throw UnsupportedError(loadError);
  } on ArgumentError {
    final dotDartTool = findDotDartTool();
    if (dotDartTool != null) {
      final packageNativeRoot = Directory(findPackageRoot(dotDartTool).toFilePath() + Directories.native);
      final libraryFile = File(packageNativeRoot.path + slash + storageLibraryName);
      if (libraryFile.existsSync()) {
        return DynamicLibrary.open(libraryFile.path);
      }
    }
    throw UnsupportedError(loadError);
  }
}

Uri? findDotDartTool() {
  Uri root = Platform.script.resolve(currentDirectorySymbol);

  do {
    if (File.fromUri(root.resolve(Directories.dotDartTool + slash + packageConfigJsonFile)).existsSync()) {
      return root.resolve(Directories.dotDartTool + slash);
    }
  } while (root != (root = root.resolve(parentDirectorySymbol)));

  root = Directory.current.uri;

  do {
    if (File.fromUri(root.resolve(Directories.dotDartTool + slash + packageConfigJsonFile)).existsSync()) {
      return root.resolve(Directories.dotDartTool + slash);
    }
  } while (root != (root = root.resolve(parentDirectorySymbol)));

  return null;
}

Uri findPackageRoot(Uri dotDartTool) {
  final packageConfigFile = File.fromUri(dotDartTool.resolve(packageConfigJsonFile));
  dynamic packageConfig;
  try {
    packageConfig = json.decode(packageConfigFile.readAsStringSync());
  } catch (ignore) {
    throw UnsupportedError(loadError);
  }
  final package = (packageConfig[PackageConfigFields.packages] ?? []).firstWhere(
    (element) => element[PackageConfigFields.name] == storagePackageName,
    orElse: () => throw UnsupportedError(loadError),
  );
  return packageConfigFile.uri.resolve(package[PackageConfigFields.rootUri] ?? empty);
}

String? findProjectRoot() {
  var directory = Directory.current.path;
  while (true) {
    if (File(directory + slash + pubspecYamlFile).existsSync() || File(directory + slash + pubspecYmlFile).existsSync()) return directory;
    final String parent = Directory(directory).parent.path;
    if (directory == parent) return null;
    directory = parent;
  }
}
