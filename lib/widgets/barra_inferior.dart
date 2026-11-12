import 'package:flutter/material.dart';

import '../theme/tema.dart';

/// Barra inferior escura e arredondada do Figma (Hoje · Remédios ·
/// Adicionar · Perfil), igual em todas as telas — H4 Consistência.
class BarraInferior extends StatelessWidget {
  final int indice;
  final ValueChanged<int> aoTocar;

  const BarraInferior({super.key, required this.indice, required this.aoTocar});

  static const _itens = <(IconData, String)>[
    (Icons.wb_sunny_outlined, 'Hoje'),
    (Icons.medication_outlined, 'Remédios'),
    (Icons.add, 'Adicionar'),
    (Icons.person_outline, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Cores.vinhoEscuro,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _itens.length; i++)
                Expanded(
                  child: _Item(
                    icone: _itens[i].$1,
                    rotulo: _itens[i].$2,
                    selecionado: i == indice,
                    onTap: () => aoTocar(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  const _Item({
    required this.icone,
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? Cores.vinhoEscuro : Cores.creme;
    return Semantics(
      button: true,
      selected: selecionado,
      label: rotulo,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: selecionado ? Cores.dourado : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            // IMPORTANTE: sem "min" a barra ocupava a tela inteira e
            // escondia o conteúdo (parecia que nada abria).
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: cor, size: 26),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  rotulo,
                  style: TextStyle(
                    color: cor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
