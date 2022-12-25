import 'dart:io';

import 'configuration.dart';
import 'constants.dart';

class BootstrapScript {
  final StorageConfiguration configuration;
  String content = empty;

  BootstrapScript(this.configuration);

  void code(String expression) => content += (expression + newLine);

  void file(File file) => content += (newLine + file.readAsStringSync() + newLine);

  String write() {
    if (Directory.current.listSync().whereType<Directory>().any((element) => element.path.endsWith(luaDirectory))) {
      code(extendPackagePathluaScript(Directory.current.path + luaDirectory));
    }
    if (Directory.current.listSync().whereType<Directory>().any((element) => element.path.endsWith(nativeDirectory))) {
      code(extendPackageNativePathluaScript(Directory.current.path + nativeDirectory));
    }
    return configuration.write() + newLine + content;
  }
}
