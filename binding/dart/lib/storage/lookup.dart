import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform, Directory, File;

import 'constants.dart';

class StorageLibrary {
  final DynamicLibrary library;
  final String path;

  StorageLibrary(this.library, this.path);
}

StorageLibrary loadBindingLibrary() {
  try {
    return StorageLibrary(
        Platform.isLinux ? DynamicLibrary.open(storageLibraryName) : throw UnsupportedError(Directory.current.path + slash + storageLibraryName), Directory.current.path + slash + storageLibraryName);
  } on ArgumentError {
    final dotDartTool = findDotDartTool();
    if (dotDartTool != null) {
      final packageNativeRoot = Directory(findPackageRoot(dotDartTool).toFilePath() + Directories.native);
      final libraryFile = File(packageNativeRoot.path + slash + storageLibraryName);
      if (libraryFile.existsSync()) {
        return StorageLibrary(DynamicLibrary.open(libraryFile.path), libraryFile.path);
      }
      throw UnsupportedError(loadError(libraryFile.path));
    }
    throw UnsupportedError(unableToFindProjectRoot);
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
    throw UnsupportedError(unableToFindProjectRoot);
  }
  final package = (packageConfig[PackageConfigFields.packages] ?? []).firstWhere(
    (element) => element[PackageConfigFields.name] == storagePackageName,
    orElse: () => throw UnsupportedError(unableToFindProjectRoot),
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
