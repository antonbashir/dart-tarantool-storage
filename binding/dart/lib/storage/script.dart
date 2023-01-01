import 'dart:io';

import 'configuration.dart';
import 'constants.dart';

class StorageBootstrapScript {
  final StorageConfiguration _configuration;
  bool _hasStorageLuaModule = false;
  String _content = empty;

  StorageBootstrapScript(this._configuration);

  get hasStorageLuaModule => _hasStorageLuaModule;

  void includeStorageLuaModule() => _hasStorageLuaModule = true;

  void code(String expression) => _content += (expression + newLine);

  void file(File file) => _content += (newLine + file.readAsStringSync() + newLine);

  String write() {
    if (Directory.current.listSync().whereType<Directory>().any((element) => element.path.endsWith(Directories.lua))) {
      code(LuaExpressions.extendPackagePath(Directory.current.path + Directories.lua));
    }
    if (Directory.current.listSync().whereType<Directory>().any((element) => element.path.endsWith(Directories.native))) {
      code(LuaExpressions.extendPackageNativePath(Directory.current.path + Directories.native));
    }
    if (_hasStorageLuaModule) code(LuaExpressions.require(storageLuaModule));
    return _configuration.format() + newLine + _content;
  }
}
