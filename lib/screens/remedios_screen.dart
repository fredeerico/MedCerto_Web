import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../services/banco.dart';
import '../services/estado.dart';
import '../theme/tema.dart';
import '../utils/datas.dart';
import '../widgets/componentes.dart';
import 'detalhes_screen.dart';

/// Tela "03 - Seus Remédios" do Figma.
class RemediosScreen extends StatefulWidget {
  const RemediosScreen({super.key});

  @override
  State<RemediosScreen> createState() => _RemediosScreenState();
}

class _RemediosScreenState extends State<RemediosScreen> {
  List<Medicamento> _meds = [];

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
    final meds = await Banco.instance.listarMedicamentos();
    if (mounted) setState(() => _meds = meds);
  }

  /// "Próxima: hoje, 12:10" / "amanhã, 08:00" / "Pausado".
  String _proxima(Medicamento m) {
    if (!m.ativo) return 'Lembretes pausados';
    final agora = DateTime.now();
    for (var k = 0; k < 8; k++) {
      final dia = soData(agora).add(Duration(days: k));
      if (!m.tomaNoDia(dia)) continue;
      for (final h in m.horarios) {
        if (noDia(dia, h).isAfter(agora)) {
          final quando = k == 0 ? 'hoje' : k == 1 ? 'amanhã' : diasCurtos[dia.weekday - 1];
          return 'Próxima: $quando, $h';
        }
      }
    }
    return m.horarios.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final ativos = _meds.where((m) => m.ativo).length;
    final acabando = _meds
        .where((m) => m.ativo && (m.diasRestantes ?? 999) <= 7)
        .toList();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ativos == 1 ? '1 remédio em uso' : '$ativos remédios em uso',
                        style: TextStyle(fontSize: 17, color: corSuave(context)),
                      ),
                      const Text('Seus remédios',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Adicionar remédio',
                  button: true,
                  child: Material(
                    color: Cores.vinho,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => abaAtual.value = 2,
                      child: const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(Icons.add, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (final m in acabando) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Cores.cremeAmarelo,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Cores.dourado.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Cores.marrom, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: m.nome,
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          TextSpan(
                              text: m.diasRestantes == 0
                                  ? ' acabou. Lembre de comprar.'
                                  : ' acaba em ${m.diasRestantes} dias. Lembre de comprar.'),
                        ]),
                        style: const TextStyle(fontSize: 16, color: Cores.marrom),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 6),
            if (_meds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  'Você ainda não cadastrou remédios.\nToque no + para começar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: corSuave(context)),
                ),
              ),
            for (final m in _meds) ...[
              Cartao(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DetalhesScreen(medId: m.id!),
                )),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Opacity(
                  opacity: m.ativo ? 1 : 0.55,
                  child: Row(
                    children: [
                      IconeRemedio(cor: m.cor),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.nomeCompleto,
                                style: const TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(m.ativo ? Icons.schedule : Icons.pause_circle_outline,
                                    size: 17, color: corSuave(context)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(_proxima(m),
                                      style: TextStyle(
                                          fontSize: 16, color: corSuave(context))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 30),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
