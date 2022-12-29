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
    if (Directory.current.listSync().whereType<Directory>().any((element) => element.path.endsWith(luaDirectory))) {
      code(LuaExpressions.extendPackagePath(Directory.current.path + luaDirectory));
    }
    if (Directory.current.listSync().whereType<Directory>().any((element) => element.path.endsWith(nativeDirectory))) {
      code(LuaExpressions.extendPackageNativePath(Directory.current.path + nativeDirectory));
    }
    return _configuration.format() + newLine + _content;
  }
}
