import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobi_ai/shared/providers.dart';

void main() {
  group('FiltroPeriodoNotifier Tests', () {
    test('Deve iniciar com o período de 30 dias', () {
      final container = ProviderContainer();
      final filtro = container.read(filtroPeriodoProvider);
      expect(filtro.tipo, PeriodoTipo.ultimos30);
    });

    test('Deve alterar o período corretamente', () {
      final container = ProviderContainer();
      final notifier = container.read(filtroPeriodoProvider.notifier);

      notifier.selecionar(PeriodoTipo.hoje);

      expect(container.read(filtroPeriodoProvider).tipo, PeriodoTipo.hoje);
    });

    test('Deve alternar o estado de comparação', () {
      final container = ProviderContainer();
      final notifier = container.read(filtroPeriodoProvider.notifier);

      notifier.alternarComparacao();
      expect(container.read(filtroPeriodoProvider).comparar, isTrue);

      notifier.alternarComparacao();
      expect(container.read(filtroPeriodoProvider).comparar, isFalse);
    });
  });

  group('LinhaSelecionadaNotifier Tests', () {
    test('Deve filtrar por linha e limpar corretamente', () {
      final container = ProviderContainer();
      final notifier = container.read(linhaSelecionadaProvider.notifier);

      notifier.selecionar('01');
      expect(container.read(linhaSelecionadaProvider), '01');

      notifier.selecionar(null);
      expect(container.read(linhaSelecionadaProvider), isNull);
    });
  });
}
