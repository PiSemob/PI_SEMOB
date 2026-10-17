import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ferret_bi/shared/providers.dart';

void main() {
  group('SessaoProvider Tests (Caixa Branca)', () {
    test('Deve iniciar com sessão nula', () {
      final container = ProviderContainer();
      final sessao = container.read(sessaoProvider);
      expect(sessao, isNull);
    });

    test('Deve atualizar o usuário ao chamar entrar()', () {
      final container = ProviderContainer();
      final notifier = container.read(sessaoProvider.notifier);
      
      notifier.entrar('gestor@semob.gov.br');
      
      expect(container.read(sessaoProvider), 'gestor@semob.gov.br');
    });
  });
}
