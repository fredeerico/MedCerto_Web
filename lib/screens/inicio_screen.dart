import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/biometria.dart';
import '../services/estado.dart';
import '../theme/tema.dart';
import '../widgets/componentes.dart';
import '../widgets/layout_web.dart';
import 'pin_screen.dart';
import 'shell_screen.dart';

/// Tela "01 - Início" do Figma.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  void _entrarComPin(BuildContext context) {
    final temPin = prefsNotifier.value.pin.isNotEmpty;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PinScreen(criando: !temPin),
    ));
  }

  /// "Entrar com digital": o Android mostra a tela do sensor.
  /// Precisa ter um PIN criado antes (é a alternativa se a digital falhar).
  Future<void> _entrarComDigital(BuildContext context) async {
    if (prefsNotifier.value.pin.isEmpty) {
      mostrarAviso('Primeiro crie um PIN. Depois você pode entrar com a digital.');
      _entrarComPin(context);
      return;
    }
    final resultado = await Biometria.instance.entrar();
    if (!context.mounted) return;
    if (resultado == ResultadoDigital.ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ShellScreen()),
        (_) => false,
      );
      return;
    }
    final aviso = Biometria.mensagem(resultado);
    if (aviso != null) mostrarAviso(aviso);
  }

  @override
  Widget build(BuildContext context) {
    final tela = MediaQuery.sizeOf(context);
    final computador = tela.width >= kLarguraComputador;
    // Os enfeites são proporcionais a "largura": a tela toda no celular,
    // ou só o lado esquerdo da página no computador.
    final largura = computador ? math.min(tela.width * 0.42, 520.0) : tela.width;

    // Fundo decorativo: círculos e pílulas.
    final enfeites = SizedBox(
      width: largura,
      height: largura * 1.1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -largura * 0.35,
            left: -largura * 0.3,
            child: CirculoDecorativo(
                tamanho: largura * 1.05, cor: Cores.vinhoEscuro.withValues(alpha: 0.55)),
          ),
          Positioned(
            top: largura * 0.32,
            right: -largura * 0.25,
            child: CirculoDecorativo(tamanho: largura * 0.85, cor: Cores.vinhoClaro),
          ),
          Positioned(
            top: largura * 0.22,
            left: largura * 0.42,
            child: Pilula(
                comprimento: largura * 0.32,
                corA: Cores.dourado,
                corB: Colors.white,
                angulo: -0.65),
          ),
          Positioned(
            top: largura * 0.62,
            left: largura * 0.1,
            child: CirculoDecorativo(tamanho: largura * 0.2, cor: Cores.rosa),
          ),
          Positioned(
            top: largura * 0.78,
            left: largura * 0.58,
            child: Pilula(
                comprimento: largura * 0.27,
                corA: Cores.dourado,
                corB: Cores.cremeAmarelo,
                comprimido: true,
                angulo: -0.55),
          ),
          Positioned(
            top: largura * 0.93,
            left: largura * 0.42,
            child: CirculoDecorativo(tamanho: largura * 0.1, cor: Cores.rosaClaro),
          ),
        ],
      ),
    );

    final conteudo = SafeArea(
      child: LayoutBuilder(
        builder: (context, limites) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: limites.maxHeight),
            child: IntrinsicHeight(
              child: _conteudo(context, centralizar: computador),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Cores.vinho,
      body: computador
          // Computador: enfeites à esquerda, texto e botões à direita.
          ? Row(
              children: [
                Expanded(child: Center(child: enfeites)),
                SizedBox(width: math.min(480.0, tela.width * 0.45), child: conteudo),
                SizedBox(width: math.max(24.0, tela.width * 0.08)),
              ],
            )
          // Celular: igual ao app (enfeites atrás do conteúdo).
          : Stack(
              children: [
                Positioned(top: 0, left: 0, child: enfeites),
                conteudo,
              ],
            ),
    );
  }

  Widget _conteudo(BuildContext context, {bool centralizar = false}) {
    return Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Cores.dourado,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medication_outlined,
                            color: Cores.vinhoEscuro, size: 30),
                      ),
                      const SizedBox(width: 10),
                      const Text('MedCerto',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: 'Seus remédios,\n',
                          style: TextStyle(color: Colors.white)),
                      TextSpan(
                          text: 'na hora certa.',
                          style: TextStyle(color: Cores.dourado)),
                    ]),
                    style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w800, height: 1.15),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'O app avisa, você confirma, e a família pode acompanhar de longe.',
                    style: TextStyle(color: Colors.white, fontSize: 18, height: 1.35),
                  ),
                  const SizedBox(height: 28),
                  BotaoGrande(
                    texto: 'Entrar com digital',
                    icone: Icons.fingerprint,
                    fundo: Cores.dourado,
                    corTexto: Cores.vinhoEscuro,
                    onPressed: () => _entrarComDigital(context),
                  ),
                  const SizedBox(height: 14),
                  BotaoGrande(
                    texto: 'Entrar com PIN',
                    contorno: true,
                    corTexto: Colors.white,
                    onPressed: () => _entrarComPin(context),
                  ),
                  if (centralizar) const Spacer(),
                ],
              ),
            );
  }
}
