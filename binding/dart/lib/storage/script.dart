import 'dart:io';

import 'configuration.dart';
import 'constants.dart';

class BootstrapScript {
  final StorageConfiguration _configuration;
  String _content = empty;

  BootstrapScript(this._configuration);

  void code(String expression) => _content += (expression + newLine);

  void file(File file) => _content += (newLine + file.readAsStringSync() + newLine);

  String write() {
    if (Directory.current.listSync().whereType<Directory>().any((element) => element.path.endsWith(Directories.lua))) {
      code(LuaExpressions.extendPackagePath(Directory.current.path + Directories.lua));
    }
    if (Directory.current.listSync().whereType<Directory>().any((element) => element.path.endsWith(Directories.native))) {
      code(LuaExpressions.extendPackageNativePath(Directory.current.path + Directories.native));
    }
    return _configuration.format() + newLine + _content;
  }
}
