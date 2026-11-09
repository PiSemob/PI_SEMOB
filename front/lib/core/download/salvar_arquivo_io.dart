import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> salvarArquivo(String nome, String tipo, Uint8List bytes) async {
  Directory? pasta;
  try {
    pasta = await getDownloadsDirectory();
  } catch (_) {
    pasta = null;
  }
  pasta ??= await getApplicationDocumentsDirectory();
  final File arquivo = File('${pasta.path}${Platform.pathSeparator}$nome');
  await arquivo.writeAsBytes(bytes, flush: true);
  return 'Arquivo salvo em ${arquivo.path}';
}
