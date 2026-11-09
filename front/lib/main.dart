import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/api/api_client.dart';
import 'core/autenticacao/servico_autenticacao.dart';
import 'core/autenticacao/sessao.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';

  final Sessao? sessao = await restaurarSessao();
  runApp(ProviderScope(
    overrides: <Override>[sessaoInicialProvider.overrideWithValue(sessao)],
    child: const MobiAiApp(),
  ));
}

Future<Sessao?> restaurarSessao() async {
  const ArmazenamentoSessao armazenamento = ArmazenamentoSessao();
  final String? token = await armazenamento.lerToken();
  if (token == null) return null;
  if (modoDemo) {
    return Sessao(
        email: 'gestor@semob.gov.br',
        nome: 'Gestor SEMOB',
        token: token,
        admin: true);
  }
  try {
    return Sessao.daApi(await ApiClient().eu(token), token);
  } on ErroApi catch (erro) {
    if (erro.naoAutorizado) await armazenamento.apagar();
    return null;
  }
}

class MobiAiApp extends ConsumerWidget {
  const MobiAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Ferret',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
