import 'dart:io';

import 'configuration.dart';
import 'constants.dart';

class StorageBootstrapScript {
  final StorageConfiguration _configuration;
  bool _hasStorageLuaModule = false;
  String _content = empty;

  StorageBootstrapScript(this._configuration);

  bool get hasStorageLuaModule => _hasStorageLuaModule;

  StorageConfiguration get configuration => _configuration;

  void code(String expression) => _content += (expression + newLine);

  void file(File file) => _content += (newLine + file.readAsStringSync() + newLine);

  void includeStorageLuaModule() => _hasStorageLuaModule = true;

  void includeLuaModulePath(String directory) => code(LuaExpressions.extendPackagePath(directory));

  void includeNativeModulePath(String directory) => code(LuaExpressions.extendPackageNativePath(directory));

  String write() {
    if (Directory.current.listSync().whereType<Directory>().any((element) => element.path.endsWith(Directories.lua))) {
      includeLuaModulePath(Directory.current.path + Directories.lua);
    }
    if (Directory.current.listSync().whereType<Directory>().any((element) => element.path.endsWith(Directories.native))) {
      includeNativeModulePath(Directory.current.path + Directories.native);
    }
    if (_hasStorageLuaModule) code(LuaExpressions.require(storageLuaModule));
    return _configuration.format() + newLine + _content;
  }
}
