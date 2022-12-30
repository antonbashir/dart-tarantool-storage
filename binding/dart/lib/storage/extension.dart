import 'dart:ffi';
import 'dart:io';

import 'package:tarantool_storage/storage/lookup.dart';

import 'constants.dart';

class ExtensionModule {
  final String libraryName;
  final String libraryPath;
  final DynamicLibrary library;

  const ExtensionModule(this.libraryName, this.libraryPath, this.library);

  static ExtensionModule loadByFile(String library) {
    try {
      return ExtensionModule(
        library,
        Directory.current.path + slash + library,
        Platform.isLinux ? DynamicLibrary.open(library) : throw UnsupportedError(loadError),
      );
    } on ArgumentError {
      final projectRoot = findProjectRoot();
      if (projectRoot == null) throw UnsupportedError(loadError);
      final libraryFile = File(projectRoot + Directories.native + slash + library);
      if (libraryFile.existsSync()) return ExtensionModule(library, libraryFile.path, DynamicLibrary.open(libraryFile.path));
      throw UnsupportedError(loadError);
    }
  }

  static ExtensionModule loadByName(String name) {
    name = name + dot + FileExtensions.so;
    try {
      return ExtensionModule(
        name,
        Directory.current.path + slash + name,
        Platform.isLinux ? DynamicLibrary.open(name) : throw UnsupportedError(loadError),
      );
    } on ArgumentError {
      final projectRoot = findProjectRoot();
      if (projectRoot == null) throw UnsupportedError(loadError);
      final libraryFile = File(projectRoot + Directories.native + slash + name);
      if (libraryFile.existsSync()) return ExtensionModule(name, libraryFile.path, DynamicLibrary.open(libraryFile.path));
      throw UnsupportedError(loadError);
    }
  }

  void unload() => _dlClose(library.handle);

  ExtensionModule reload() {
    _dlClose(library.handle);
    return loadByFile(libraryPath);
  }

  int Function(Pointer<Void>) get _dlClose => _standartLibrary.lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(dlCloseFunction).asFunction();

  DynamicLibrary get _standartLibrary => DynamicLibrary.process();
}
