import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class BairroMapa {
  const BairroMapa(this.nome, this.contorno, this.centro);

  final String nome;
  final List<Offset> contorno;
  final Offset centro;
}

class DadosMapa {
  const DadosMapa({
    required this.municipio,
    required this.bairros,
    required this.vias,
    required this.pontos,
  });

  final List<Offset> municipio;
  final List<BairroMapa> bairros;
  final List<List<Offset>> vias;
  final Map<String, Offset> pontos;

  Offset? local(String nome) {
    final Offset? ponto = pontos[nome];
    if (ponto != null) return ponto;
    for (final BairroMapa b in bairros) {
      if (b.nome == nome) return b.centro;
    }
    return null;
  }

  static Future<DadosMapa>? _cache;

  static DadosMapa? carregados;

  static Future<DadosMapa> carregar(AssetBundle bundle) =>
      _cache ??= _ler(bundle).then((DadosMapa d) => carregados = d);

  static Future<DadosMapa> _ler(AssetBundle bundle) async {
    Future<List<dynamic>> features(String arquivo) async {
      final Map<String, dynamic> json =
          jsonDecode(await bundle.loadString('assets/mapas/$arquivo'))
              as Map<String, dynamic>;
      return json['features'] as List<dynamic>;
    }

    List<Offset> linha(List<dynamic> coords) => <Offset>[
          for (final dynamic c in coords)
            Offset((c[0] as num).toDouble(), (c[1] as num).toDouble()),
        ];
    Map<String, dynamic> geometria(dynamic f) =>
        (f as Map<String, dynamic>)['geometry'] as Map<String, dynamic>;
    String nome(dynamic f) => ((f as Map<String, dynamic>)['properties']
        as Map<String, dynamic>)['nome'] as String;
    List<Offset> anel(dynamic f) => linha(
        (geometria(f)['coordinates'] as List<dynamic>).first as List<dynamic>);

    final List<dynamic> municipio =
        await features('sao_caetano_do_sul.geojson');
    final List<dynamic> bairros = await features('bairros.geojson');
    final List<dynamic> vias = await features('vias_principais.geojson');
    final List<dynamic> pontos = await features('pontos.geojson');

    return DadosMapa(
      municipio: anel(municipio.first),
      bairros: <BairroMapa>[
        for (final dynamic f in bairros)
          () {
            final List<Offset> c = anel(f);
            final Offset soma =
                c.fold(Offset.zero, (Offset a, Offset p) => a + p);
            return BairroMapa(nome(f), c, soma / c.length.toDouble());
          }(),
      ],
      vias: <List<Offset>>[
        for (final dynamic f in vias)
          linha(geometria(f)['coordinates'] as List<dynamic>),
      ],
      pontos: <String, Offset>{
        for (final dynamic f in pontos)
          nome(f): Offset(
            ((geometria(f)['coordinates'] as List<dynamic>)[0] as num)
                .toDouble(),
            ((geometria(f)['coordinates'] as List<dynamic>)[1] as num)
                .toDouble(),
          ),
      },
    );
  }
}

class FluxoMapa {
  const FluxoMapa({
    required this.origem,
    required this.destino,
    required this.peso,
    this.destaque = false,
    this.curvatura = 1,
  });

  final String origem;
  final String destino;
  final double peso;

  final bool destaque;

  final double curvatura;
}

class MapaMunicipio extends StatelessWidget {
  const MapaMunicipio({
    super.key,
    this.fluxos = const <FluxoMapa>[],
    this.rotularDestinos = false,
  });

  final List<FluxoMapa> fluxos;

  final bool rotularDestinos;

  @override
  Widget build(BuildContext context) {
    final TextStyle rotulo = DefaultTextStyle.of(context).style.merge(
          AppTextStyles.caption
              .copyWith(fontSize: 11, color: AppColors.textSecondary),
        );
    Widget desenho(DadosMapa dados) => Semantics(
          label: fluxos.isEmpty
              ? 'Mapa do município de São Caetano do Sul'
              : 'Mapa de São Caetano do Sul com o fluxo de viagens de cada linha',
          child: CustomPaint(
            size: Size.infinite,
            painter: _MapaPainter(dados, rotulo, fluxos, rotularDestinos),
          ),
        );

    final DadosMapa? prontos = DadosMapa.carregados;
    if (prontos != null) return desenho(prontos);
    return FutureBuilder<DadosMapa>(
      future: DadosMapa.carregar(DefaultAssetBundle.of(context)),
      builder: (BuildContext context, AsyncSnapshot<DadosMapa> snap) =>
          snap.hasData ? desenho(snap.data!) : const SizedBox.expand(),
    );
  }
}

class _MapaPainter extends CustomPainter {
  _MapaPainter(
      this.dados, this.estiloRotulo, this.fluxos, this.rotularDestinos);

  final DadosMapa dados;
  final TextStyle estiloRotulo;
  final List<FluxoMapa> fluxos;
  final bool rotularDestinos;

  static const double _margem = 14;

  static const double _inclinacao = 52 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    if (dados.municipio.isEmpty || size.isEmpty) return;

    double minLon = double.infinity, maxLon = -double.infinity;
    double minLat = double.infinity, maxLat = -double.infinity;
    for (final Offset p in dados.municipio) {
      minLon = math.min(minLon, p.dx);
      maxLon = math.max(maxLon, p.dx);
      minLat = math.min(minLat, p.dy);
      maxLat = math.max(maxLat, p.dy);
    }
    final double fatorLon = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final Offset centro = Offset((minLon + maxLon) / 2, (minLat + maxLat) / 2);
    final double extensao =
        math.max((maxLon - minLon) * fatorLon, maxLat - minLat);

    const double t = _inclinacao;
    final double distancia = extensao * 3.2;
    final double espessura = extensao * 0.05;

    Offset bruto(Offset lonLat, [double z = 0]) {
      final double x = (lonLat.dx - centro.dx) * fatorLon;
      final double y = lonLat.dy - centro.dy;
      final double vertical = y * math.cos(t) + z * math.sin(t);
      final double profundidade = distancia + y * math.sin(t) - z * math.cos(t);
      final double p = distancia / profundidade;
      return Offset(x * p, -vertical * p);
    }

    final List<_Arco> arcos = <_Arco>[];
    double maiorPeso = 0;
    for (final FluxoMapa f in fluxos) {
      final Offset? a = dados.local(f.origem);
      final Offset? b = dados.local(f.destino);
      if (a == null || b == null) continue;
      maiorPeso = math.max(maiorPeso, f.peso);
      final double comprimento =
          Offset((b.dx - a.dx) * fatorLon, b.dy - a.dy).distance;
      final double altura =
          (comprimento * 0.22 + extensao * 0.03) * f.curvatura;
      arcos.add(_Arco(f, a, b, <Offset>[
        for (int i = 0; i <= 28; i++)
          () {
            final double s = i / 28;
            return bruto(Offset.lerp(a, b, s)!, altura * 4 * s * (1 - s));
          }(),
      ]));
    }

    final List<Offset> todos = <Offset>[
      for (final Offset p in dados.municipio) bruto(p),
      for (final Offset p in dados.municipio) bruto(p, -espessura),
      for (final _Arco a in arcos) ...a.pontos,
    ];
    final Rect caixa = _caixa(todos);
    final double escala = math.min(
      (size.width - 2 * _margem) / caixa.width,
      (size.height - 2 * _margem) / caixa.height,
    );
    final Offset deslocamento = Offset(
      (size.width - caixa.width * escala) / 2 - caixa.left * escala,
      (size.height - caixa.height * escala) / 2 - caixa.top * escala,
    );
    Offset tela(Offset b) => b * escala + deslocamento;
    Offset projetar(Offset lonLat, [double z = 0]) => tela(bruto(lonLat, z));

    Path poligono(List<Offset> pontos,
            {double z = 0, bool fechar = true}) =>
        Path()
          ..addPolygon(
              <Offset>[for (final Offset p in pontos) projetar(p, z)], fechar);

    final Path topo = poligono(dados.municipio);

    canvas.drawPath(
      poligono(dados.municipio, z: -espessura).shift(const Offset(0, 3)),
      Paint()
        ..color = AppColors.sombra
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final Paint parede = Paint()..color = AppColors.mapaBairro;
    final List<Offset> m = dados.municipio;
    for (int i = 0; i < m.length - 1; i++) {
      canvas.drawPath(
        Path()
          ..addPolygon(<Offset>[
            projetar(m[i]),
            projetar(m[i + 1]),
            projetar(m[i + 1], -espessura),
            projetar(m[i], -espessura),
          ], true),
        parede,
      );
    }
    canvas.drawPath(topo, Paint()..color = AppColors.mapaMunicipio);

    canvas.save();
    canvas.clipPath(topo);
    final Paint bairro = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.mapaBairro;
    for (final BairroMapa b in dados.bairros) {
      canvas.drawPath(poligono(b.contorno), bairro);
    }
    final Paint via = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.mapaVia;
    for (final List<Offset> v in dados.vias) {
      canvas.drawPath(poligono(v, fechar: false), via);
    }
    canvas.restore();

    canvas.drawPath(
      topo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.mapaContorno,
    );

    _desenharFluxos(canvas, arcos, maiorPeso, projetar, tela);

    for (final MapEntry<String, Offset> e in dados.pontos.entries) {
      _marcador(canvas, projetar(e.value), raio: 4.5);
      _rotulo(canvas, e.key, projetar(e.value) + const Offset(8, 0));
    }
  }

  void _desenharFluxos(
    Canvas canvas,
    List<_Arco> arcos,
    double maiorPeso,
    Offset Function(Offset, [double]) projetar,
    Offset Function(Offset) tela,
  ) {
    if (arcos.isEmpty) return;
    final bool algumDestaque = arcos.any((_Arco a) => a.fluxo.destaque);
    arcos.sort((_Arco a, _Arco b) {
      if (a.fluxo.destaque != b.fluxo.destaque) {
        return a.fluxo.destaque ? 1 : -1;
      }
      return a.fluxo.peso.compareTo(b.fluxo.peso);
    });
    final Set<String> rotulados = <String>{};
    for (final _Arco a in arcos) {
      final bool apagado = algumDestaque && !a.fluxo.destaque;
      final double largura =
          1.5 + 5 * (maiorPeso == 0 ? 0 : a.fluxo.peso / maiorPeso);

      canvas.drawLine(
        projetar(a.origem),
        projetar(a.destino),
        Paint()
          ..strokeWidth = 1
          ..color =
              AppColors.mapaContorno.withValues(alpha: apagado ? 0.25 : 0.6),
      );
      final Path caminho = Path()
        ..addPolygon(<Offset>[for (final Offset p in a.pontos) tela(p)], false);
      canvas.drawPath(
        caminho,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = largura
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.primary.withValues(alpha: apagado ? 0.18 : 0.8),
      );
      final Offset fim = projetar(a.destino);
      _marcador(canvas, fim, raio: 3.5, apagado: apagado);
      if (rotularDestinos && !apagado && rotulados.add(a.fluxo.destino)) {
        _rotulo(canvas, a.fluxo.destino, fim + const Offset(6, 0));
      }
    }
  }

  void _marcador(Canvas canvas, Offset p,
      {required double raio, bool apagado = false}) {
    canvas.drawCircle(p, raio, Paint()..color = AppColors.surface);
    canvas.drawCircle(
      p,
      raio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.primary.withValues(alpha: apagado ? 0.3 : 1),
    );
  }

  void _rotulo(Canvas canvas, String texto, Offset esquerda) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: texto, style: estiloRotulo),
      textDirection: TextDirection.ltr,
    )..layout();
    final Offset canto = esquerda - Offset(0, tp.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(canto.dx - 3, canto.dy - 1, tp.width + 6, tp.height + 2),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.surface.withValues(alpha: 0.85),
    );
    tp.paint(canvas, canto);
  }

  static Rect _caixa(List<Offset> pontos) {
    double l = double.infinity, t = double.infinity;
    double r = -double.infinity, b = -double.infinity;
    for (final Offset p in pontos) {
      l = math.min(l, p.dx);
      t = math.min(t, p.dy);
      r = math.max(r, p.dx);
      b = math.max(b, p.dy);
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  @override
  bool shouldRepaint(_MapaPainter antigo) =>
      antigo.dados != dados ||
      antigo.estiloRotulo != estiloRotulo ||
      antigo.fluxos != fluxos ||
      antigo.rotularDestinos != rotularDestinos;
}

class _Arco {
  _Arco(this.fluxo, this.origem, this.destino, this.pontos);

  final FluxoMapa fluxo;
  final Offset origem;
  final Offset destino;

  final List<Offset> pontos;
}
