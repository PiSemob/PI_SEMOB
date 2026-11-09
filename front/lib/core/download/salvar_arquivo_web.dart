import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String> salvarArquivo(String nome, String tipo, Uint8List bytes) async {
  final web.Blob blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: tipo),
  );
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement link = web.HTMLAnchorElement()
    ..href = url
    ..download = nome;
  web.document.body!.append(link);
  link.click();
  link.remove();
  web.URL.revokeObjectURL(url);
  return 'Download iniciado: $nome';
}
