import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tema.dart';

/// A partir desta largura a página usa o layout de computador
/// (menu na lateral e conteúdo em coluna no centro).
const double kLarguraComputador = 800;

bool telaDeComputador(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kLarguraComputador;

/// Deixa uma tela do app com cara de página de site: o fundo ocupa a janela
/// inteira e o conteúdo fica numa coluna no centro, com largura confortável
/// para ler. Em telas estreitas (celular) não muda nada.
///
/// Dentro da coluna, `MediaQuery.sizeOf(context)` devolve o tamanho DA
/// COLUNA; por isso os enfeites das telas (círculos, pílulas), que são
/// calculados pela largura, continuam proporcionais.
class ColunaWeb extends StatelessWidget {
  final Widget child;

  /// Largura máxima da coluna.
  final double largura;

  /// Cor das laterais.
  final Color fundo;

  /// Se informado, a coluna vira um "cartão" com esta altura máxima e
  /// cantos arredondados (usado no PIN e na tela do alarme).
  final double? alturaMaxima;

  const ColunaWeb({
    super.key,
    required this.child,
    required this.fundo,
    this.largura = 760,
    this.alturaMaxima,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, limites) {
        final w = math.min(largura, limites.maxWidth);
        var h = limites.maxHeight;
        final limite = alturaMaxima;
        if (limite != null && w < limites.maxWidth && h > limite + 48) {
          h = limite;
        }
        final cartao = h < limites.maxHeight;
        return ColoredBox(
          color: fundo,
          child: Center(
            child: SizedBox(
              width: w,
              height: h,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cartao ? 28 : 0),
                child: MediaQuery(
                  data: mq.copyWith(size: Size(w, h)),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Menu lateral do site (computador): as mesmas 4 opções da barra inferior
/// do app — Hoje · Remédios · Adicionar · Perfil.
class MenuLateral extends StatelessWidget {
  final int indice;
  final ValueChanged<int> aoTocar;

  const MenuLateral({super.key, required this.indice, required this.aoTocar});

  static const _itens = <(IconData, String)>[
    (Icons.wb_sunny_outlined, 'Hoje'),
    (Icons.medication_outlined, 'Remédios'),
    (Icons.add, 'Adicionar'),
    (Icons.person_outline, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Cores.vinhoEscuro,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 28),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Cores.dourado,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication_outlined,
                      color: Cores.vinhoEscuro, size: 28),
                ),
                const SizedBox(width: 10),
                const Text('MedCerto',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          for (var i = 0; i < _itens.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ItemMenu(
                icone: _itens[i].$1,
                rotulo: _itens[i].$2,
                selecionado: i == indice,
                onTap: () => aoTocar(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  const _ItemMenu({
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
      child: Material(
        color: selecionado ? Cores.dourado : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icone, color: cor, size: 26),
                const SizedBox(width: 12),
                Text(
                  rotulo,
                  style: TextStyle(
                      color: cor, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
