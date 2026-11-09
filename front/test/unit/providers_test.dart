import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobi_ai/core/autenticacao/sessao.dart';
import 'package:mobi_ai/core/router/app_router.dart';

class _ArmazenamentoFalso extends ArmazenamentoSessao {
  String? token;

  @override
  Future<bool> guardar(String novo) async {
    token = novo;
    return true;
  }

  @override
  Future<bool> apagar() async {
    token = null;
    return true;
  }
}

const Sessao _ana =
    Sessao(email: 'ana@semob.sp.gov.br', nome: 'Ana Maria Souza', token: 'tk');

void main() {
  group('Sessão (Caixa Branca)', () {
    late _ArmazenamentoFalso armazenamento;
    late ProviderContainer container;

    setUp(() {
      armazenamento = _ArmazenamentoFalso();
      container = ProviderContainer(overrides: <Override>[
        armazenamentoSessaoProvider.overrideWithValue(armazenamento),
      ]);
    });

    test('Deve iniciar com sessão nula', () {
      expect(container.read(sessaoProvider), isNull);
    });

    test('Começa com a sessão restaurada na abertura do app', () {
      final ProviderContainer restaurado = ProviderContainer(
          overrides: <Override>[sessaoInicialProvider.overrideWithValue(_ana)]);
      expect(restaurado.read(sessaoProvider), _ana);
    });

    test('Entrar guarda o token e sair apaga', () {
      container.read(sessaoProvider.notifier).entrar(_ana);
      expect(container.read(sessaoProvider)?.email, 'ana@semob.sp.gov.br');
      expect(armazenamento.token, 'tk');

      container.read(sessaoProvider.notifier).sair();
      expect(container.read(sessaoProvider), isNull);
      expect(armazenamento.token, isNull);
    });

    test('Sessão expirada fica marcada para o aviso do login', () {
      final SessaoNotifier sessao = container.read(sessaoProvider.notifier);
      sessao.entrar(_ana);
      sessao.expirou();
      expect(container.read(sessaoProvider), isNull);
      expect(sessao.expirada, isTrue);
    });
  });

  test('Iniciais do nome para o avatar', () {
    expect(_ana.iniciais, 'AS');
    expect(const Sessao(email: 'x@y.z', nome: 'Bia', token: '').iniciais, 'B');
  });

  test('Sessão lê o perfil de administrador da API', () {
    final Map<String, dynamic> usuario = <String, dynamic>{
      'email': 'ana@semob.sp.gov.br',
      'nome': 'Ana',
      'admin': true,
    };
    expect(Sessao.daApi(usuario, 'tk').admin, isTrue);
    expect(
        Sessao.daApi(<String, dynamic>{...usuario, 'admin': false}, 'tk').admin,
        isFalse);
  });

  group('Proteção das rotas', () {
    test('Sem login, telas internas levam ao login', () {
      expect(protegerRota(false, '/dashboard'), '/login');
      expect(protegerRota(false, '/assistente'), '/login');
    });

    test('Telas de acesso abrem sem login', () {
      expect(protegerRota(false, '/login'), isNull);
      expect(protegerRota(false, '/recuperar-senha'), isNull);
      expect(protegerRota(false, '/redefinir-senha'), isNull);
      expect(protegerRota(false, '/criar-senha'), isNull);
    });

    test('Só administrador abre a tela de usuários', () {
      expect(protegerRota(true, '/usuarios'), '/dashboard');
      expect(protegerRota(true, '/usuarios', admin: true), isNull);
      expect(protegerRota(false, '/usuarios', admin: true), '/login');
    });

    test('Logado, o login leva ao painel', () {
      expect(protegerRota(true, '/login'), '/dashboard');
      expect(protegerRota(true, '/operacao'), isNull);
    });
  });
}
