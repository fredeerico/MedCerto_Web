import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medicamento.dart';
import '../services/acoes.dart';
import '../services/banco.dart';
import '../theme/tema.dart';
import '../widgets/componentes.dart';
import '../widgets/layout_web.dart';

/// Tela cheia "Hora do remédio" (Figma: tela com o relógio 12:10).
/// Abre quando a pessoa toca na notificação, sem pedir PIN.
class AlarmeScreen extends StatefulWidget {
  final int medId;
  final String horario;

  /// true quando o alarme abriu o app (celular bloqueado ou app fechado):
  /// ao responder, o app fecha e volta para a tela de bloqueio, em vez de
  /// deixar o app inteiro acessível sem desbloquear o celular.
  final bool fecharAppAoTerminar;

  const AlarmeScreen({
    super.key,
    required this.medId,
    required this.horario,
    this.fecharAppAoTerminar = false,
  });

  @override
  State<AlarmeScreen> createState() => _AlarmeScreenState();
}

class _AlarmeScreenState extends State<AlarmeScreen> {
  Medicamento? _med;

  @override
  void initState() {
    super.initState();
    Banco.instance.buscarMedicamento(widget.medId).then((m) {
      if (mounted) setState(() => _med = m);
    });
  }

  void _fechar() {
    if (!mounted) return;
    if (widget.fecharAppAoTerminar) {
      SystemNavigator.pop(); // fecha o app; o celular continua bloqueado
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => ColunaWeb(
        fundo: const Color(0xFF2B1216),
        largura: 460,
        alturaMaxima: 860,
        child: Builder(builder: _pagina),
      );

  Widget _pagina(BuildContext context) {
    final m = _med;
    final largura = MediaQuery.sizeOf(context).width;
    // Botão "voltar" do Android também fecha o app quando ele foi aberto
    // pelo alarme, para não mostrar as outras telas sem desbloquear.
    return PopScope(
      canPop: !widget.fecharAppAoTerminar,
      onPopInvokedWithResult: (jaSaiu, _) {
        if (!jaSaiu) _fechar();
      },
      child: Scaffold(
      backgroundColor: Cores.vinhoEscuro,
      body: Stack(
        children: [
          Positioned(
            top: largura * 0.35,
            left: -largura * 0.15,
            child: CirculoDecorativo(
                tamanho: largura * 1.3, cor: const Color(0xFF55000D).withValues(alpha: 0.7)),
          ),
          SafeArea(
            child: ColunaRolavel(
              alinhamento: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, color: Colors.white, size: 26),
                      SizedBox(width: 8),
                      Text('Hora do remédio',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.horario,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 84,
                        fontWeight: FontWeight.w800,
                        height: 1.1)),
                const SizedBox(height: 24),
                if (m != null) ...[
                  Pilula(
                    comprimento: largura * 0.3,
                    corA: paresPilula[m.cor % paresPilula.length].$1,
                    corB: paresPilula[m.cor % paresPilula.length].$2,
                  ),
                  const SizedBox(height: 28),
                  Text(m.nomeCompleto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    '${m.textoQuantidade}${m.observacao.isEmpty ? '' : ' · ${m.observacao}'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Cores.rosa, fontSize: 20),
                  ),
                ],
                const Spacer(),
                const SizedBox(height: 24),
                BotaoGrande(
                  texto: 'Já tomei',
                  icone: Icons.check,
                  fundo: Cores.dourado,
                  corTexto: Cores.vinhoEscuro,
                  onPressed: m == null
                      ? null
                      : () async {
                          await Acoes.tomar(m, widget.horario);
                          _fechar();
                        },
                ),
                const SizedBox(height: 14),
                BotaoGrande(
                  texto: 'Lembrar em 10 min',
                  icone: Icons.schedule,
                  contorno: true,
                  corTexto: Colors.white,
                  onPressed: m == null
                      ? null
                      : () async {
                          await Acoes.adiar(m, widget.horario);
                          _fechar();
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
