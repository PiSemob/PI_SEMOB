import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../notificacoes.dart';
import '../formatters.dart';

class SinoNotificacoes extends ConsumerWidget {
  const SinoNotificacoes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Notificacao>> avisos =
        ref.watch(notificacoesProvider);
    final Set<String> vistas = ref.watch(notificacoesVistasProvider);
    final List<Notificacao> lista = avisos.valueOrNull ?? const <Notificacao>[];
    final int novas =
        lista.where((Notificacao n) => !vistas.contains(n.id)).length;

    final Widget icone = Badge(
      isLabelVisible: novas > 0,
      label: Text(novas > 9 ? '9+' : '$novas'),
      child: const Icon(Icons.notifications_none,
          size: 21, color: AppColors.textSecondary),
    );

    return PopupMenuButton<Notificacao?>(
      tooltip: avisos.hasError ? 'Notificações indisponíveis' : 'Notificações',
      icon: icone,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 380),
      onOpened: () => ref
          .read(notificacoesVistasProvider.notifier)
          .marcar(lista.map((Notificacao n) => n.id)),
      onSelected: (Notificacao? n) {
        if (n != null) context.go(n.rota);
      },
      itemBuilder: (BuildContext context) {
        if (avisos.isLoading && lista.isEmpty) {
          return const <PopupMenuEntry<Notificacao?>>[
            PopupMenuItem<Notificacao?>(
                enabled: false, child: Text('Carregando…')),
          ];
        }
        if (avisos.hasError) {
          return <PopupMenuEntry<Notificacao?>>[
            PopupMenuItem<Notificacao?>(
              enabled: false,
              child: Text(
                'Não consegui buscar as notificações: ${avisos.error is ErroApi ? avisos.error : 'API fora do ar'}',
                style: AppTextStyles.caption,
              ),
            ),
          ];
        }
        if (lista.isEmpty) {
          return const <PopupMenuEntry<Notificacao?>>[
            PopupMenuItem<Notificacao?>(
              enabled: false,
              child: Text('Nada que precise de atenção nos últimos 7 dias.',
                  style: AppTextStyles.caption),
            ),
          ];
        }
        return <PopupMenuEntry<Notificacao?>>[
          for (final Notificacao n in lista.take(12))
            PopupMenuItem<Notificacao?>(
              value: n,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  n.tipo == 'anomalia'
                      ? Icons.warning_amber_rounded
                      : Icons.directions_bus_outlined,
                  color: n.tipo == 'anomalia'
                      ? AppColors.warning
                      : AppColors.textSecondary,
                  size: 20,
                ),
                title: Text(n.titulo, style: AppTextStyles.label),
                subtitle: Text('${fmtData(n.data)} · ${n.texto}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption),
              ),
            ),
        ];
      },
    );
  }
}

class AtualizacaoPeriodica extends ConsumerStatefulWidget {
  const AtualizacaoPeriodica({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AtualizacaoPeriodica> createState() =>
      _AtualizacaoPeriodicaState();
}

class _AtualizacaoPeriodicaState extends ConsumerState<AtualizacaoPeriodica> {
  static const Duration _intervalo = Duration(seconds: 60);

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_intervalo, (_) {
      ref.invalidate(apiNoArProvider);
      ref.invalidate(notificacoesProvider);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
