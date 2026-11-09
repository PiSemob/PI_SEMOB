library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'salvar_arquivo_io.dart'
    if (dart.library.js_interop) 'salvar_arquivo_web.dart' as plataforma;

typedef SalvarArquivo = Future<String> Function(
    String nome, String tipo, Uint8List bytes);

final Provider<SalvarArquivo> salvarArquivoProvider =
    Provider<SalvarArquivo>((Ref ref) => plataforma.salvarArquivo);
