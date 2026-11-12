import 'package:flutter/material.dart';

import '../theme/tema.dart';

/// Pares de cor das pílulas (cada remédio recebe um).
const paresPilula = <(Color, Color)>[
  (Cores.vinho, Cores.rosa),
  (Cores.dourado, Colors.white),
  (Color(0xFF4B2A7A), Color(0xFFF3D9B1)),
  (Color(0xFF9B1C1C), Color(0xFFF3D9B1)),
  (Color(0xFFB98A8F), Cores.rosaClaro),
];

/// Pílula desenhada (cápsula de duas cores ou comprimido com risco).
class Pilula extends StatelessWidget {
  final double comprimento;
  final Color corA;
  final Color corB;
  final double angulo;
  final bool contorno; // só o contorno (cartão "Agora")
  final bool comprimido; // comprimido com risco no meio (Detalhes)

  const Pilula({
    super.key,
    this.comprimento = 28,
    this.corA = Cores.vinho,
    this.corB = Cores.rosa,
    this.angulo = -0.7,
    this.contorno = false,
    this.comprimido = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angulo,
      child: CustomPaint(
        size: Size(comprimento, comprimento * 0.48),
        painter: _PilulaPainter(corA, corB, contorno, comprimido),
      ),
    );
  }
}

class _PilulaPainter extends CustomPainter {
  final Color a, b;
  final bool contorno, comprimido;
  _PilulaPainter(this.a, this.b, this.contorno, this.comprimido);

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(size.height / 2));
    final traco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.07
      ..color = a;

    if (contorno) {
      canvas.drawRRect(r, traco);
      canvas.drawLine(Offset(size.width / 2, size.height * 0.12),
          Offset(size.width / 2, size.height * 0.88), traco);
      return;
    }

    canvas.save();
    canvas.clipRRect(r);
    if (comprimido) {
      canvas.drawRect(Offset.zero & size, Paint()..color = b);
    } else {
      canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width / 2, size.height), Paint()..color = a);
      canvas.drawRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
          Paint()..color = b);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.12, size.height * 0.2, size.width * 0.22,
            size.height * 0.14),
        Radius.circular(size.height),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    canvas.restore();

    if (comprimido) {
      canvas.drawRRect(r, traco..strokeWidth = size.height * 0.04);
      canvas.drawLine(Offset(size.width / 2, size.height * 0.12),
          Offset(size.width / 2, size.height * 0.88), traco);
    } else {
      canvas.drawRRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.black.withValues(alpha: 0.08));
    }
  }

  @override
  bool shouldRepaint(covariant _PilulaPainter old) =>
      old.a != a || old.b != b || old.contorno != contorno;
}

/// Quadradinho creme com a pílula do remédio (lista de remédios).
class IconeRemedio extends StatelessWidget {
  final int cor;
  final double tamanho;
  const IconeRemedio({super.key, required this.cor, this.tamanho = 48});

  @override
  Widget build(BuildContext context) {
    final par = paresPilula[cor % paresPilula.length];
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: Cores.creme,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Pilula(comprimento: tamanho * 0.62, corA: par.$1, corB: par.$2),
    );
  }
}

/// Cartão branco com sombra leve (borda preta no alto contraste).
class Cartao extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color cor;
  final Color? corBorda;

  const Cartao({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.cor = Colors.white,
    this.corBorda,
  });

  @override
  Widget build(BuildContext context) {
    final contraste = altoContraste(context);
    return Material(
      color: cor,
      elevation: contraste ? 0 : 1.5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: corBorda != null
            ? BorderSide(color: corBorda!, width: 1.5)
            : contraste
                ? const BorderSide(color: Colors.black, width: 1.5)
                : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Botão grande (altura 60 — bem acima dos 48dp do RNF04).
class BotaoGrande extends StatelessWidget {
  final String texto;
  final IconData? icone;
  final VoidCallback? onPressed;
  final Color fundo;
  final Color corTexto;
  final bool contorno;

  const BotaoGrande({
    super.key,
    required this.texto,
    this.icone,
    required this.onPressed,
    this.fundo = Cores.vinhoEscuro,
    this.corTexto = Colors.white,
    this.contorno = false,
  });

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700, color: corTexto);
    final conteudo = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icone != null) ...[
          Icon(icone, color: corTexto, size: 22),
          const SizedBox(width: 10),
        ],
        Flexible(child: Text(texto, style: estilo, textAlign: TextAlign.center)),
      ],
    );
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: contorno
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                shape: forma,
                side: BorderSide(color: corTexto.withValues(alpha: 0.6), width: 1.5),
              ),
              child: conteudo,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: fundo,
                disabledBackgroundColor: fundo.withValues(alpha: 0.4),
                shape: forma,
              ),
              child: conteudo,
            ),
    );
  }
}

/// Botão quadrado branco com seta (canto superior esquerdo do Figma).
class BotaoVoltar extends StatelessWidget {
  final VoidCallback? onTap;
  const BotaoVoltar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Voltar',
      button: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () => Navigator.of(context).maybePop(),
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.arrow_back, color: Cores.texto, size: 26),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta pequena ("Tomado", "AGORA · 12:10", "Leitura clara").
class Etiqueta extends StatelessWidget {
  final String texto;
  final Color fundo;
  final Color cor;
  final IconData? icone;
  final double tamanhoFonte;

  const Etiqueta({
    super.key,
    required this.texto,
    required this.fundo,
    required this.cor,
    this.icone,
    this.tamanhoFonte = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(20),
      ),
      // Text.rich (em vez de Row + Flexible) funciona em qualquer lugar,
      // inclusive dentro de outra Row, sem erro de largura infinita.
      child: Text.rich(
        TextSpan(children: [
          if (icone != null) ...[
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(icone, size: tamanhoFonte + 2, color: cor),
            ),
            const TextSpan(text: ' '),
          ],
          TextSpan(text: texto),
        ]),
        style: TextStyle(
            color: cor, fontSize: tamanhoFonte, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Título de seção em maiúsculas ("RESTO DO DIA", "HORÁRIOS").
class TituloSecao extends StatelessWidget {
  final String texto;
  final Color? cor;
  const TituloSecao(this.texto, {super.key, this.cor});

  @override
  Widget build(BuildContext context) => Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: cor ?? corSuave(context),
        ),
      );
}

/// Avatar quadrado dourado com a inicial ("D").
class AvatarInicial extends StatelessWidget {
  final String inicial;
  final double tamanho;
  const AvatarInicial(this.inicial, {super.key, this.tamanho = 56});

  @override
  Widget build(BuildContext context) => Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(
          color: Cores.dourado,
          borderRadius: BorderRadius.circular(tamanho * 0.28),
        ),
        alignment: Alignment.center,
        child: Text(
          inicial,
          style: TextStyle(
            fontSize: tamanho * 0.45,
            fontWeight: FontWeight.w800,
            color: Cores.vinhoEscuro,
          ),
        ),
      );
}

/// Círculo decorativo de fundo (cabeçalhos vinho).
class CirculoDecorativo extends StatelessWidget {
  final double tamanho;
  final Color cor;
  const CirculoDecorativo({super.key, required this.tamanho, required this.cor});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: tamanho,
          height: tamanho,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
      );
}

/// Coluna que ocupa a tela toda (para usar Spacer) mas rola quando a letra
/// está grande ou a tela é pequena — evita faixa amarela de overflow.
class ColunaRolavel extends StatelessWidget {
  final EdgeInsets padding;
  final CrossAxisAlignment alinhamento;
  final List<Widget> children;

  const ColunaRolavel({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 24),
    this.alinhamento = CrossAxisAlignment.start,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: limites.maxHeight > padding.vertical
                ? limites.maxHeight - padding.vertical
                : 0.0,
          ),
          child: IntrinsicHeight(
            child: Column(crossAxisAlignment: alinhamento, children: children),
          ),
        ),
      ),
    );
  }
}
