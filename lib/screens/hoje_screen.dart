import 'dart:async';

import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../services/acoes.dart';
import '../services/banco.dart';
import '../services/estado.dart';
import '../theme/tema.dart';
import '../utils/datas.dart';
import '../utils/validacao.dart';
import '../widgets/componentes.dart';
import 'detalhes_screen.dart';

class _Dose {
  final Medicamento med;
  final String horario;
  final DateTime quando;
  final bool tomada;
  const _Dose(this.med, this.horario, this.quando, this.tomada);
}

/// Tela "02 - hoje" do Figma. Mostra o status de cada dose do dia
/// (H1 Visibilidade do status; H6 Reconhecimento em vez de memorização).
class HojeScreen extends StatefulWidget {
  const HojeScreen({super.key});

  @override
  State<HojeScreen> createState() => _HojeScreenState();
}

class _HojeScreenState extends State<HojeScreen> {
  List<_Dose> _doses = [];
  List<(int, int)> _semana = []; // (feitas, previstas) dos últimos 7 dias
  int _pctSemana = 100;
  bool _carregando = true;
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    dadosMudaram.addListener(_carregar);
    _carregar();
    // Atualiza "AGORA/ATRASADA" com o passar do tempo.
    _relogio = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    dadosMudaram.removeListener(_carregar);
    _relogio?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    final meds = await Banco.instance.listarMedicamentos();
    final hoje = DateTime.now();
    final inicio = soData(hoje).subtract(const Duration(days: 6));
    final regs = await Banco.instance.registrosEntre(dataChave(inicio), dataChave(hoje));
    final tomadas = {for (final r in regs) '${r.medId}|${r.data}|${r.horario}'};

    final doses = <_Dose>[];
    for (final m in meds) {
      if (!m.tomaNoDia(hoje)) continue;
      for (final h in m.horarios) {
        doses.add(_Dose(m, h, noDia(hoje, h),
            tomadas.contains('${m.id}|${dataChave(hoje)}|$h')));
      }
    }
    doses.sort((a, b) => a.quando.compareTo(b.quando));

    final semana = <(int, int)>[];
    var totalFeitas = 0, totalPrevistas = 0;
    for (var k = 0; k < 7; k++) {
      final dia = inicio.add(Duration(days: k));
      final chave = dataChave(dia);
      var previstas = 0, feitas = 0;
      for (final m in meds) {
        if (!m.tomaNoDia(dia)) continue;
        previstas += m.horarios.length;
        feitas += m.horarios
            .where((h) => tomadas.contains('${m.id}|$chave|$h'))
            .length;
      }
      semana.add((feitas, previstas));
      totalFeitas += feitas;
      totalPrevistas += previstas;
    }

    if (!mounted) return;
    setState(() {
      _doses = doses;
      _semana = semana;
      _pctSemana = percentual(totalFeitas, totalPrevistas);
      _carregando = false;
    });
  }

  void _abrirDetalhes(Medicamento m) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DetalhesScreen(medId: m.id!),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final pendentes = _doses.where((d) => !d.tomada).toList();
    final destaque = pendentes.isEmpty ? null : pendentes.first;
    final resto = _doses.where((d) => d != destaque).toList();
    final feitasHoje = _doses.where((d) => d.tomada).length;

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Cabecalho(
            agora: agora,
            nome: prefsNotifier.value.nome,
            feitas: feitasHoje,
            total: _doses.length,
            pctSemana: _pctSemana,
            semana: _semana,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_carregando)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_doses.isEmpty)
                  _Vazio(onAdicionar: () => abaAtual.value = 2)
                else ...[
                  if (destaque != null)
                    _CartaoAgora(dose: destaque, agora: agora)
                  else
                    const _TudoCerto(),
                  if (resto.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const TituloSecao('Resto do dia'),
                    const SizedBox(height: 12),
                    for (final d in resto) ...[
                      _LinhaDose(
                        dose: d,
                        atrasada: !d.tomada &&
                            agora.difference(d.quando).inMinutes > 30,
                        onTap: () => _abrirDetalhes(d.med),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final DateTime agora;
  final String nome;
  final int feitas, total, pctSemana;
  final List<(int, int)> semana;

  const _Cabecalho({
    required this.agora,
    required this.nome,
    required this.feitas,
    required this.total,
    required this.pctSemana,
    required this.semana,
  });

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final inicio = soData(agora).subtract(const Duration(days: 6));
    return Container(
      decoration: const BoxDecoration(
        color: Cores.vinho,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -largura * 0.25,
            right: -largura * 0.2,
            child: CirculoDecorativo(tamanho: largura * 0.6, cor: Cores.vinhoClaro),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dataPorExtenso(agora),
                      style: const TextStyle(color: Colors.white, fontSize: 17)),
                  const SizedBox(height: 2),
                  Text(
                    '${saudacao(agora)}${nome.isEmpty ? '' : ', $nome'}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              label: '$feitas de $total doses tomadas hoje',
                              excludeSemantics: true,
                              child: Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: '$feitas',
                                    style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                                TextSpan(
                                    text: '/$total',
                                    style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: Cores.rosa)),
                              ])),
                            ),
                            const Text('doses hoje',
                                style: TextStyle(color: Colors.white, fontSize: 17)),
                            Text('$pctSemana% na semana',
                                style: const TextStyle(
                                    color: Cores.dourado,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      // Barrinhas dos últimos 7 dias.
                      for (var k = 0; k < semana.length; k++)
                        Padding(
                          padding: const EdgeInsets.only(left: 7),
                          child: _Barra(
                            feitas: semana[k].$1,
                            previstas: semana[k].$2,
                            hoje: k == 6,
                            rotulo: k == 6
                                ? 'Hoje'
                                : iniciaisDias[
                                    inicio.add(Duration(days: k)).weekday - 1],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  final int feitas, previstas;
  final bool hoje;
  final String rotulo;
  const _Barra({
    required this.feitas,
    required this.previstas,
    required this.hoje,
    required this.rotulo,
  });

  @override
  Widget build(BuildContext context) {
    const altura = 56.0;
    final fracao = previstas == 0 ? 0.0 : feitas / previstas;
    return Column(
      children: [
        Container(
          width: 14,
          height: altura,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 14,
            height: altura * fracao,
            decoration: BoxDecoration(
              color: hoje ? Cores.dourado : Cores.rosaClaro,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(rotulo,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// Cartão amarelo "AGORA · 12:10" com "Já tomei" e "+10 min".
class _CartaoAgora extends StatelessWidget {
  final _Dose dose;
  final DateTime agora;
  const _CartaoAgora({required this.dose, required this.agora});

  @override
  Widget build(BuildContext context) {
    final m = dose.med;
    final minutos = agora.difference(dose.quando).inMinutes;
    final String rotulo;
    if (minutos < 0) {
      rotulo = 'PRÓXIMA · ${dose.horario}';
    } else if (minutos <= 30) {
      rotulo = 'AGORA · ${dose.horario}';
    } else {
      rotulo = 'ATRASADA · ${dose.horario}';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Cores.cremeAmarelo,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: altoContraste(context) ? Colors.black : Cores.dourado, width: 1.5),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 4,
            top: 4,
            child: Pilula(comprimento: 46, corA: Cores.rosa, contorno: true, angulo: -0.5),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Etiqueta(texto: rotulo, fundo: Cores.vinhoEscuro, cor: Cores.dourado),
              const SizedBox(height: 10),
              Text(m.nomeCompleto,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                '${m.textoQuantidade}${m.observacao.isEmpty ? '' : ' · ${m.observacao}'}',
                style: TextStyle(fontSize: 17, color: corSuave(context)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: () => Acoes.tomar(m, dose.horario),
                        icon: const Icon(Icons.check, size: 24),
                        label: const Text('Já tomei',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Cores.vinho,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: () => Acoes.adiar(m, dose.horario),
                        icon: const Icon(Icons.schedule, size: 22),
                        label: const Text('+10 min',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Cores.texto,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinhaDose extends StatelessWidget {
  final _Dose dose;
  final bool atrasada;
  final VoidCallback onTap;
  const _LinhaDose({required this.dose, required this.atrasada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = dose.med;
    return Cartao(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconeRemedio(cor: m.cor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.nome,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                Text([dose.horario, if (m.dose.isNotEmpty) m.dose].join(' · '),
                    style: TextStyle(fontSize: 16, color: corSuave(context))),
              ],
            ),
          ),
          if (dose.tomada)
            const Etiqueta(
                texto: 'Tomado',
                icone: Icons.check,
                fundo: Cores.verdeClaro,
                cor: Cores.verde)
          else if (atrasada)
            const Etiqueta(
                texto: 'Atrasado',
                icone: Icons.schedule,
                fundo: Cores.rosaClaro,
                cor: Cores.vinho),
        ],
      ),
    );
  }
}

class _TudoCerto extends StatelessWidget {
  const _TudoCerto();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Cores.verdeClaro,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Cores.verde, size: 36),
            SizedBox(width: 14),
            Expanded(
              child: Text('Tudo certo! Você tomou todas as doses de hoje.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _Vazio extends StatelessWidget {
  final VoidCallback onAdicionar;
  const _Vazio({required this.onAdicionar});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(height: 24),
          const Pilula(comprimento: 90, corA: Cores.dourado, corB: Colors.white),
          const SizedBox(height: 24),
          const Text('Nenhum remédio para hoje',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Cadastre seu primeiro remédio e o app avisa na hora certa.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: corSuave(context))),
          const SizedBox(height: 24),
          BotaoGrande(
              texto: 'Adicionar remédio', icone: Icons.add, onPressed: onAdicionar),
        ],
      );
}
