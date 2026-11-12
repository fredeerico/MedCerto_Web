import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../services/banco.dart';
import '../services/estado.dart';
import '../services/notificacoes.dart';
import '../theme/tema.dart';
import '../utils/datas.dart';
import '../utils/validacao.dart';
import '../widgets/componentes.dart';
import '../widgets/layout_web.dart';
import 'digitar_screen.dart';

/// Tela "04 - Detalhes do Remédio" do Figma.
class DetalhesScreen extends StatefulWidget {
  final int medId;
  const DetalhesScreen({super.key, required this.medId});

  @override
  State<DetalhesScreen> createState() => _DetalhesScreenState();
}

class _DetalhesScreenState extends State<DetalhesScreen> {
  Medicamento? _med;
  Set<String> _tomadas = {};
  bool _carregou = false;

  @override
  void initState() {
    super.initState();
    dadosMudaram.addListener(_carregar);
    _carregar();
  }

  @override
  void dispose() {
    dadosMudaram.removeListener(_carregar);
    super.dispose();
  }

  Future<void> _carregar() async {
    final m = await Banco.instance.buscarMedicamento(widget.medId);
    final hoje = DateTime.now();
    final inicio = soData(hoje).subtract(const Duration(days: 6));
    final regs = await Banco.instance
        .registrosEntre(dataChave(inicio), dataChave(hoje), medId: widget.medId);
    if (!mounted) return;
    setState(() {
      _med = m;
      _tomadas = {for (final r in regs) '${r.data}|${r.horario}'};
      _carregou = true;
    });
  }

  Future<void> _alternarAtivo(bool ativo) async {
    final m = _med!.copyWith(ativo: ativo);
    await Banco.instance.salvarMedicamento(m);
    if (ativo) {
      await Notificacoes.instance.agendarMedicamento(m);
    } else {
      await Notificacoes.instance.cancelarMedicamento(m.id!);
    }
    avisarMudanca();
    mostrarAviso(ativo ? 'Lembretes ligados de novo.' : 'Lembretes pausados.');
  }

  /// Remover pede confirmação (H5 Prevenção de erros).
  Future<void> _remover() async {
    final m = _med!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover ${m.nome}?'),
        content: const Text(
          'Os lembretes deste remédio vão parar. Se só quer dar uma pausa, use "Pausar lembretes".',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(fontSize: 17))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Cores.erro),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Notificacoes.instance.cancelarMedicamento(m.id!);
    await Banco.instance.removerMedicamento(m.id!);
    avisarMudanca();
    if (mounted) Navigator.of(context).pop();
    mostrarAviso('${m.nome} foi removido.');
  }

  @override
  Widget build(BuildContext context) => ColunaWeb(
        fundo: Cores.rosaClaro,
        largura: 720,
        child: Builder(builder: _pagina),
      );

  Widget _pagina(BuildContext context) {
    final m = _med;
    if (!_carregou) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (m == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Remédio não encontrado.')),
      );
    }

    final largura = MediaQuery.sizeOf(context).width;
    final par = paresPilula[m.cor % paresPilula.length];
    final hoje = DateTime.now();
    final inicio = soData(hoje).subtract(const Duration(days: 6));

    // Últimos 7 dias: verde = tudo tomado, rosa = faltou, cinza = não tinha.
    var previstas = 0, feitas = 0;
    final dias = <(String, int)>[]; // (letra, 0 sem dose / 1 ok / 2 faltou / 3 em andamento)
    for (var k = 0; k < 7; k++) {
      final dia = inicio.add(Duration(days: k));
      final letra = iniciaisDias[dia.weekday - 1];
      if (!m.tomaNoDia(dia)) {
        dias.add((letra, 0));
        continue;
      }
      final chave = dataChave(dia);
      final ok = m.horarios.where((h) => _tomadas.contains('$chave|$h')).length;
      previstas += m.horarios.length;
      feitas += ok;
      if (ok == m.horarios.length) {
        dias.add((letra, 1));
      } else if (k == 6) {
        dias.add((letra, 3));
      } else {
        dias.add((letra, 2));
      }
    }
    final pct = percentual(feitas, previstas);
    final restantes = m.diasRestantes;

    return Scaffold(
      backgroundColor: Cores.rosaClaro,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Topo rosa com a pílula grande.
          SizedBox(
            height: largura * 0.85,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: largura * 0.22,
                  child: CirculoDecorativo(tamanho: largura * 0.68, cor: Cores.rosa.withValues(alpha: 0.6)),
                ),
                Positioned(
                  top: largura * 0.38,
                  child: Pilula(
                    comprimento: largura * 0.48,
                    corA: m.cor == 0 ? const Color(0xFFE3B98F) : par.$1,
                    corB: Cores.cremeAmarelo,
                    comprimido: true,
                    angulo: -0.65,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          const BotaoVoltar(),
                          const Spacer(),
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => DigitarScreen(editar: m)),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20, color: Cores.texto),
                                    SizedBox(width: 6),
                                    Text('Editar',
                                        style: TextStyle(
                                            fontSize: 17, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Painel creme.
          Container(
            constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.6),
            decoration: const BoxDecoration(
              color: Cores.creme,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(m.nomeCompleto,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    ),
                    Etiqueta(
                      texto: m.textoDias,
                      fundo: Cores.rosaClaro,
                      cor: Cores.vinhoEscuro,
                      tamanhoFonte: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [m.dose, m.textoQuantidade, if (m.observacao.isNotEmpty) m.observacao]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: TextStyle(fontSize: 17, color: corSuave(context)),
                ),
                const SizedBox(height: 18),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Cartao(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const TituloSecao('Horários'),
                              const SizedBox(height: 6),
                              for (final h in m.horarios)
                                Text(h,
                                    style: const TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Cartao(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const TituloSecao('Na caixa'),
                              const SizedBox(height: 6),
                              if (m.caixa <= 0)
                                Text('Não informado',
                                    style: TextStyle(fontSize: 16, color: corSuave(context)))
                              else ...[
                                Text.rich(TextSpan(children: [
                                  TextSpan(
                                      text: '${m.estoque} ',
                                      style: const TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.w800)),
                                  const TextSpan(text: 'comp.', style: TextStyle(fontSize: 15)),
                                ])),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: (m.estoque / m.caixa).clamp(0.0, 1.0),
                                    minHeight: 8,
                                    color: Cores.dourado,
                                    backgroundColor: Cores.rosaClaro,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  restantes == null
                                      ? ''
                                      : restantes == 0
                                          ? 'Acabou'
                                          : 'Acaba em $restantes dias',
                                  style: TextStyle(fontSize: 14, color: corSuave(context)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Cartao(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Últimos 7 dias',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          ),
                          Text('$pct% em dia',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: pct >= 80 ? Cores.verde : Cores.vinho)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final d in dias) _BolinhaDia(letra: d.$1, estado: d.$2),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Cartao(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: m.ativo,
                    onChanged: _alternarAtivo,
                    title: const Text('Lembretes ligados',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        m.ativo ? 'O alarme toca nos horários' : 'Pausado: o alarme não toca',
                        style: const TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _remover,
                  icon: const Icon(Icons.delete_outline, color: Cores.erro),
                  label: const Text('Remover remédio',
                      style: TextStyle(fontSize: 17, color: Cores.erro)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BolinhaDia extends StatelessWidget {
  final String letra;
  final int estado; // 0 sem dose, 1 ok, 2 faltou, 3 hoje em andamento
  const _BolinhaDia({required this.letra, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (Color fundo, Color cor, IconData? icone) = switch (estado) {
      1 => (Cores.verdeClaro, Cores.verde, Icons.check),
      2 => (Cores.rosaClaro, Cores.vinho, Icons.close),
      3 => (Cores.cremeAmarelo, Cores.marrom, Icons.more_horiz),
      _ => (const Color(0xFFF1EDE8), Cores.textoSuave, null),
    };
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(10)),
          child: icone == null ? null : Icon(icone, color: cor, size: 22),
        ),
        const SizedBox(height: 6),
        Text(letra,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cor)),
      ],
    );
  }
}
