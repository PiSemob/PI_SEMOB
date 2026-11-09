import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_widgets.dart';

class Secao extends StatelessWidget {
  const Secao({super.key, required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(titulo.toUpperCase(), style: AppTextStyles.overline),
          ),
          child,
        ],
      ),
    );
  }
}

class OpcaoLigaDesliga extends StatelessWidget {
  const OpcaoLigaDesliga({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.onChanged,
  });

  final String titulo;
  final String descricao;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(titulo, style: AppTextStyles.label),
              Text(descricao, style: AppTextStyles.caption),
            ],
          ),
        ),
        Switch(value: valor, onChanged: onChanged),
      ],
    );
  }
}

class DuasColunas extends StatelessWidget {
  const DuasColunas({super.key, required this.esquerda, required this.direita});

  final Widget esquerda;
  final Widget direita;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        if (c.maxWidth < 700) {
          return Column(
            children: <Widget>[
              esquerda,
              const SizedBox(height: AppSpacing.md),
              direita,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: esquerda),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: direita),
          ],
        );
      },
    );
  }
}

class ErroDeCarga extends StatelessWidget {
  const ErroDeCarga({
    super.key,
    required this.titulo,
    required this.mensagem,
    required this.onTentarDeNovo,
  });

  final String titulo;
  final String mensagem;
  final VoidCallback onTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            EmptyState(
              icone: Icons.cloud_off_outlined,
              mensagem: '$titulo\n$mensagem',
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 200,
              child: AppButton(
                label: 'Tentar de novo',
                icone: Icons.refresh,
                secundario: true,
                onPressed: onTentarDeNovo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
