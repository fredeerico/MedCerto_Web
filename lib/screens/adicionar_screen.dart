import 'package:flutter/material.dart';

import '../theme/tema.dart';
import '../widgets/componentes.dart';
import 'digitar_screen.dart';

/// Tela "Adicionar": hoje o cadastro é digitando (com sugestão de nomes).
/// O cadastro por voz está planejado e aparece como "Em breve".
class AdicionarScreen extends StatelessWidget {
  const AdicionarScreen({super.key});

  void _digitar(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const DigitarScreen()));

  Future<void> _vozEmBreve(BuildContext context) async {
    final digitar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.mic_none, size: 36, color: Cores.vinho),
        title: const Text('Cadastro por voz: em breve'),
        content: const Text(
          'Estamos trabalhando para você cadastrar o remédio só falando o nome, '
          'a dose e o horário.\n\nPor enquanto, use a opção Digitar.',
          style: TextStyle(fontSize: 17, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Entendi', style: TextStyle(fontSize: 17)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Digitar agora', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
    if (digitar == true && context.mounted) _digitar(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text('Novo remédio', style: TextStyle(fontSize: 17, color: corSuave(context))),
          const SizedBox(height: 4),
          const Text('Como você quer adicionar?',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15)),
          const SizedBox(height: 28),

          // DIGITAR (cartão principal, vinho)
          Semantics(
            button: true,
            label: 'Digitar: escreva o nome, a dose e o horário',
            excludeSemantics: true,
            child: Material(
              color: Cores.vinho,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _digitar(context),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      bottom: -50,
                      child: CirculoDecorativo(tamanho: 160, cor: Cores.vinhoClaro),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _QuadradoIcone(icone: Icons.edit_outlined, fundo: Cores.dourado),
                          SizedBox(height: 38),
                          Text('DIGITAR',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('Comece a escrever e escolha o nome na lista',
                              style: TextStyle(color: Colors.white, fontSize: 17)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // FALAR (planejado)
          Semantics(
            button: true,
            label: 'Falar: em breve',
            excludeSemantics: true,
            child: Cartao(
              onTap: () => _vozEmBreve(context),
              child: Row(
                children: [
                  const _QuadradoIcone(icone: Icons.mic_none, fundo: Cores.rosaClaro),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Falar',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        Text('Diga o nome, a dose e o horário',
                            style: TextStyle(fontSize: 16, color: corSuave(context))),
                      ],
                    ),
                  ),
                  const Etiqueta(
                    texto: 'Em breve',
                    fundo: Cores.cremeAmarelo,
                    cor: Cores.marrom,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: Cores.verdeClaro, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check, color: Cores.verde),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Você sempre confere antes de salvar.',
                    style: TextStyle(fontSize: 17)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuadradoIcone extends StatelessWidget {
  final IconData icone;
  final Color fundo;
  const _QuadradoIcone({required this.icone, required this.fundo});

  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(14)),
        child: Icon(icone, size: 30, color: Cores.vinhoEscuro),
      );
}
