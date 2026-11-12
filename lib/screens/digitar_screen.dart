import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medicamento.dart';
import '../services/banco.dart';
import '../services/estado.dart';
import '../services/notificacoes.dart';
import '../theme/tema.dart';
import '../utils/datas.dart';
import '../utils/validacao.dart';
import '../widgets/campo_nome_remedio.dart';
import '../widgets/componentes.dart';
import '../widgets/layout_web.dart';

/// Tela "04 - Digitar" do Figma (Novo remédio / Editar).
///
/// [editar]: remédio existente (null = novo remédio).
class DigitarScreen extends StatefulWidget {
  final Medicamento? editar;

  const DigitarScreen({super.key, this.editar});

  @override
  State<DigitarScreen> createState() => _DigitarScreenState();
}

class _DigitarScreenState extends State<DigitarScreen> {
  static const _periodos = <(String, String)>[
    ('Manhã', '08:00'),
    ('Almoço', '13:00'),
    ('Jantar', '19:00'),
  ];

  final _nome = TextEditingController();
  final _dose = TextEditingController();
  final _obs = TextEditingController();
  final _caixa = TextEditingController();
  int _quantidade = 1;
  final Set<String> _horarios = {};
  bool _todoDia = true;
  final Set<int> _dias = {};
  Map<String, String> _erros = {};
  bool _salvando = false;
  String _unidade = 'mg';

  @override
  void initState() {
    super.initState();
    final base = widget.editar;
    if (base != null) {
      _nome.text = base.nome;
      final (numero, unidade) = separarDose(base.dose);
      _dose.text = numero;
      _unidade = unidade;
      _obs.text = base.observacao;
      _quantidade = base.quantidade;
      _horarios.addAll(base.horarios);
      _todoDia = base.todoDia;
      _dias.addAll(base.dias);
      if (base.caixa > 0) _caixa.text = '${base.estoque}';
    }
    // Remédio novo começa sem horário marcado: a pessoa escolhe.
  }

  @override
  void dispose() {
    _nome.dispose();
    _dose.dispose();
    _obs.dispose();
    _caixa.dispose();
    super.dispose();
  }

  bool get _editando => widget.editar != null;

  List<String> get _extras => ordenarHorarios(
      _horarios.where((h) => !_periodos.any((p) => p.$2 == h)));

  /// Abre o seletor de horário com botões grandes de + e −.
  Future<void> _outroHorario() async {
    final escolhido = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Cores.creme,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _SeletorHorario(),
    );
    if (escolhido == null || !mounted) return;
    if (_horarios.contains(escolhido)) {
      mostrarAviso('O horário $escolhido já está marcado.');
      return;
    }
    setState(() {
      _horarios.add(escolhido);
      _erros.remove('horarios');
    });
  }

  Future<void> _salvar() async {
    final resultado = validarMedicamento(
      nome: _nome.text,
      dose: _dose.text,
      quantidade: _quantidade,
      horarios: _horarios.toList(),
      todoDia: _todoDia,
      dias: _dias.toList(),
      estoque: _caixa.text,
    );
    setState(() => _erros = resultado.erros);
    if (!resultado.ok) {
      mostrarAviso('Falta pouco: confira o que está em vermelho.');
      return;
    }

    final base = widget.editar;
    final textoCaixa = _caixa.text.trim();
    final estoque = textoCaixa.isEmpty ? 0 : int.parse(textoCaixa);
    final caixa = textoCaixa.isEmpty
        ? 0
        : (base == null || estoque > base.caixa ? estoque : base.caixa);

    final m = Medicamento(
      id: base?.id,
      nome: _nome.text.trim(),
      dose: montarDose(_dose.text, _unidade),
      quantidade: _quantidade,
      observacao: _obs.text.trim(),
      horarios: ordenarHorarios(_horarios),
      todoDia: _todoDia,
      dias: _todoDia ? const [] : (_dias.toList()..sort()),
      estoque: estoque,
      caixa: caixa,
      ativo: base?.ativo ?? true,
      cor: base?.cor ?? DateTime.now().second % paresPilula.length,
      criadoEm: base?.criadoEm ?? dataChave(DateTime.now()),
    );

    setState(() => _salvando = true);
    final id = await Banco.instance.salvarMedicamento(m);
    await Notificacoes.instance.agendarMedicamento(m.copyWith(id: id));
    avisarMudanca();
    if (!mounted) return;
    Navigator.of(context).pop(true);
    if (!_editando) abaAtual.value = 1;
    mostrarAviso(
        '${m.nome} salvo. Vou avisar às ${m.horarios.join(', ')}.');
  }

  @override
  Widget build(BuildContext context) => ColunaWeb(
        fundo: Theme.of(context).scaffoldBackgroundColor,
        largura: 720,
        child: Builder(builder: _pagina),
      );

  Widget _pagina(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Row(
                    children: [
                      const BotaoVoltar(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _editando ? 'Editar remédio' : 'Novo remédio',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  const TituloSecao('Nome'),
                  const SizedBox(height: 8),
                  // Sugere nomes do catálogo do servidor enquanto a pessoa digita.
                  CampoNomeRemedio(
                    controller: _nome,
                    erro: _erros['nome'],
                    onChanged: (_) {
                      if (_erros.containsKey('nome')) {
                        setState(() => _erros.remove('nome'));
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  const TituloSecao('Dose (opcional)'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dose,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            hintText: 'Ex.: 850',
                            errorText: _erros['dose'],
                            errorMaxLines: 3,
                          ),
                          onChanged: (_) => setState(() => _erros.remove('dose')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _SeletorUnidade(
                        valor: _unidade,
                        onChanged: (u) => setState(() => _unidade = u),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const TituloSecao('Comprimidos por vez'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _BotaoQuadrado(
                        icone: Icons.remove,
                        rotulo: 'Menos um comprimido',
                        onTap: _quantidade > 1
                            ? () => setState(() => _quantidade--)
                            : null,
                      ),
                      SizedBox(
                        width: 56,
                        child: Text('$_quantidade',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                      _BotaoQuadrado(
                        icone: Icons.add,
                        rotulo: 'Mais um comprimido',
                        onTap: _quantidade < 10
                            ? () => setState(() => _quantidade++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const TituloSecao('Quando você toma?'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < _periodos.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _Escolha(
                            titulo: _periodos[i].$1,
                            subtitulo: _periodos[i].$2,
                            selecionado: _horarios.contains(_periodos[i].$2),
                            onTap: () => setState(() {
                              final h = _periodos[i].$2;
                              _horarios.contains(h) ? _horarios.remove(h) : _horarios.add(h);
                              _erros.remove('horarios');
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_extras.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final h in _extras)
                          InputChip(
                            label: Text(h,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                            backgroundColor: Cores.vinho,
                            deleteIconColor: Colors.white,
                            deleteButtonTooltipMessage: 'Tirar $h',
                            onDeleted: () => setState(() => _horarios.remove(h)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                      ],
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _outroHorario,
                      icon: const Icon(Icons.add, color: Cores.vinho),
                      label: const Text('Escolher outro horário',
                          style: TextStyle(
                              fontSize: 17,
                              color: Cores.vinho,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
                  if (_erros['horarios'] != null)
                    _TextoErro(_erros['horarios']!),
                  const SizedBox(height: 14),

                  const TituloSecao('Dias'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Escolha(
                          titulo: 'Todo dia',
                          subtitulo: 'sem pausa',
                          selecionado: _todoDia,
                          onTap: () => setState(() {
                            _todoDia = true;
                            _erros.remove('dias');
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Escolha(
                          titulo: 'Alguns dias',
                          subtitulo: 'escolher',
                          selecionado: !_todoDia,
                          onTap: () => setState(() => _todoDia = false),
                        ),
                      ),
                    ],
                  ),
                  if (!_todoDia) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var d = 1; d <= 7; d++)
                          _BotaoDia(
                            letra: iniciaisDias[d - 1],
                            nome: diasCurtos[d - 1],
                            selecionado: _dias.contains(d),
                            onTap: () => setState(() {
                              _dias.contains(d) ? _dias.remove(d) : _dias.add(d);
                              _erros.remove('dias');
                            }),
                          ),
                      ],
                    ),
                  ],
                  if (_erros['dias'] != null) _TextoErro(_erros['dias']!),
                  const SizedBox(height: 24),

                  const TituloSecao('Observação (opcional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _obs,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(hintText: 'Ex.: depois do almoço'),
                  ),
                  const SizedBox(height: 20),

                  const TituloSecao('Comprimidos na caixa (opcional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _caixa,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Ex.: 30 — para avisar quando estiver acabando',
                      errorText: _erros['estoque'],
                    ),
                    onChanged: (_) => setState(() => _erros.remove('estoque')),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: BotaoGrande(
                texto: _editando ? 'Salvar alterações' : 'Salvar remédio',
                icone: Icons.check,
                onPressed: _salvando ? null : _salvar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Escolha extends StatelessWidget {
  final String titulo, subtitulo;
  final bool selecionado;
  final VoidCallback onTap;

  const _Escolha({
    required this.titulo,
    required this.subtitulo,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final corTexto = selecionado ? Colors.white : Cores.texto;
    return Semantics(
      selected: selecionado,
      button: true,
      child: Material(
        color: selecionado ? Cores.vinho : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: selecionado
              ? BorderSide.none
              : BorderSide(
                  color: altoContraste(context) ? Colors.black : const Color(0xFFEDE5E2),
                  width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titulo,
                    style: TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800, color: corTexto)),
                Text(subtitulo, style: TextStyle(fontSize: 15, color: corTexto)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoQuadrado extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final VoidCallback? onTap;
  const _BotaoQuadrado({required this.icone, required this.rotulo, this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: rotulo,
        enabled: onTap != null,
        excludeSemantics: true,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: onTap == null ? Cores.rosa : Cores.vinho, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              width: 56,
              height: 60,
              child: Icon(icone,
                  size: 28, color: onTap == null ? Cores.rosa : Cores.vinhoEscuro),
            ),
          ),
        ),
      );
}

class _BotaoDia extends StatelessWidget {
  final String letra, nome;
  final bool selecionado;
  final VoidCallback onTap;
  const _BotaoDia({
    required this.letra,
    required this.nome,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selecionado,
        label: nome,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selecionado ? Cores.vinho : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selecionado ? Cores.vinho : Cores.rosa, width: 1.5),
            ),
            child: Text(letra,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: selecionado ? Colors.white : Cores.texto)),
          ),
        ),
      );
}

class _TextoErro extends StatelessWidget {
  final String texto;
  const _TextoErro(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Cores.erro, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(texto,
                  style: const TextStyle(color: Cores.erro, fontSize: 15)),
            ),
          ],
        ),
      );
}


/// Botões mg · g · ml ao lado do campo da dose.
class _SeletorUnidade extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;
  const _SeletorUnidade({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final u in unidadesDose)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Semantics(
              button: true,
              selected: u == valor,
              label: u,
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(u),
                child: Container(
                  width: 52,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: u == valor ? Cores.vinho : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: u == valor ? Cores.vinho : Cores.rosa,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    u,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: u == valor ? Colors.white : Cores.texto,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Seletor de horário pensado para idosos: hora e minutos grandes, com
/// botões + e − (sem o relógio de ponteiros do Android).
class _SeletorHorario extends StatefulWidget {
  const _SeletorHorario();

  @override
  State<_SeletorHorario> createState() => _SeletorHorarioState();
}

class _SeletorHorarioState extends State<_SeletorHorario> {
  late int _hora;
  late int _minuto;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _hora = agora.hour;
    _minuto = (agora.minute ~/ 5) * 5;
  }

  String get _texto => hhmm(_hora, _minuto);

  String get _periodo {
    if (_hora < 6) return 'da madrugada';
    if (_hora < 12) return 'da manhã';
    if (_hora < 18) return 'da tarde';
    return 'da noite';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escolha o horário',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Toque em + ou −, ou toque no número para digitar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: corSuave(context))),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ColunaHorario(
                  rotulo: 'Hora',
                  valor: doisDigitos(_hora),
                  maximo: 23,
                  aoAumentar: () => setState(() => _hora = (_hora + 1) % 24),
                  aoDiminuir: () => setState(() => _hora = (_hora - 1) % 24),
                  aoDigitar: (n) => setState(() => _hora = n),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':',
                      style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800)),
                ),
                _ColunaHorario(
                  rotulo: 'Minutos',
                  valor: doisDigitos(_minuto),
                  maximo: 59,
                  aoAumentar: () => setState(() => _minuto = (_minuto + 5) % 60),
                  aoDiminuir: () => setState(() => _minuto = (_minuto - 5) % 60),
                  aoDigitar: (n) => setState(() => _minuto = n),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Atalhos para os minutos mais comuns.
            Wrap(
              spacing: 8,
              children: [
                for (final m in const [0, 15, 30, 45])
                  ChoiceChip(
                    label: Text(':${doisDigitos(m)}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    selected: _minuto == m,
                    onSelected: (_) => setState(() => _minuto = m),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text('$_texto $_periodo',
                style: TextStyle(fontSize: 18, color: corSuave(context))),
            const SizedBox(height: 18),
            BotaoGrande(
              texto: 'Adicionar $_texto',
              icone: Icons.check,
              fundo: Cores.vinho,
              onPressed: () => Navigator.of(context).pop(_texto),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(fontSize: 17)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColunaHorario extends StatelessWidget {
  final String rotulo;
  final String valor;
  final int maximo; // 23 para hora, 59 para minutos
  final VoidCallback aoAumentar;
  final VoidCallback aoDiminuir;
  final ValueChanged<int> aoDigitar;

  const _ColunaHorario({
    required this.rotulo,
    required this.valor,
    required this.maximo,
    required this.aoAumentar,
    required this.aoDiminuir,
    required this.aoDigitar,
  });

  /// Tocar no número abre um campo para digitar direto.
  Future<void> _digitar(BuildContext context) async {
    final numero = await showDialog<int>(
      context: context,
      builder: (_) => _DialogoNumero(rotulo: rotulo, maximo: maximo, inicial: valor),
    );
    if (numero != null) aoDigitar(numero);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(rotulo, style: TextStyle(fontSize: 15, color: corSuave(context))),
        const SizedBox(height: 6),
        _BotaoQuadrado(icone: Icons.add, rotulo: 'Aumentar $rotulo', onTap: aoAumentar),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Semantics(
            button: true,
            label: '$rotulo: $valor. Toque para digitar',
            excludeSemantics: true,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Cores.vinho, width: 2),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _digitar(context),
                child: SizedBox(
                  width: 112,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(valor,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 52, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
          ),
        ),
        _BotaoQuadrado(icone: Icons.remove, rotulo: 'Diminuir $rotulo', onTap: aoDiminuir),
      ],
    );
  }
}


/// Janela para digitar a hora ou os minutos (só números, com limite).
class _DialogoNumero extends StatefulWidget {
  final String rotulo;
  final int maximo;
  final String inicial;

  const _DialogoNumero({
    required this.rotulo,
    required this.maximo,
    required this.inicial,
  });

  @override
  State<_DialogoNumero> createState() => _DialogoNumeroState();
}

class _DialogoNumeroState extends State<_DialogoNumero> {
  late final TextEditingController _controle = TextEditingController(text: widget.inicial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.inicial.length);
  String? _erro;

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  void _confirmar() {
    final numero = int.tryParse(_controle.text.trim());
    if (numero == null || numero < 0 || numero > widget.maximo) {
      setState(() => _erro = 'Digite um número de 0 a ${widget.maximo}.');
      return;
    }
    Navigator.of(context).pop(numero);
  }

  @override
  Widget build(BuildContext context) {
    final ehHora = widget.maximo == 23;
    return AlertDialog(
      title: Text(ehHora ? 'Digite a hora' : 'Digite os minutos'),
      content: TextField(
        controller: _controle,
        autofocus: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          hintText: ehHora ? 'Ex.: 21' : 'Ex.: 30',
          helperText: ehHora ? 'De 0 a 23' : 'De 0 a 59',
          helperStyle: const TextStyle(fontSize: 15),
          errorText: _erro,
        ),
        onChanged: (_) {
          if (_erro != null) setState(() => _erro = null);
        },
        onSubmitted: (_) => _confirmar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(fontSize: 17)),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: const Text('OK', style: TextStyle(fontSize: 17)),
        ),
      ],
    );
  }
}
