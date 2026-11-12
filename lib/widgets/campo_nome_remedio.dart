import 'dart:async';

import 'package:flutter/material.dart';

import '../models/medicamento_catalogo.dart';
import '../services/api.dart';
import '../theme/tema.dart';
import '../utils/busca.dart';

/// Campo "Nome" com sugestões vindas do catálogo do servidor.
///
/// Conforme a pessoa digita, aparecem nomes de remédios para tocar e
/// escolher. Se o servidor estiver fora do ar, o campo continua funcionando
/// como um campo de texto comum (RNF11, modo degradado).
class CampoNomeRemedio extends StatefulWidget {
  final TextEditingController controller;
  final String? erro;
  final ValueChanged<String>? onChanged;
  final ValueChanged<MedicamentoCatalogo>? onEscolher;

  const CampoNomeRemedio({
    super.key,
    required this.controller,
    this.erro,
    this.onChanged,
    this.onEscolher,
  });

  @override
  State<CampoNomeRemedio> createState() => _CampoNomeRemedioState();
}

class _CampoNomeRemedioState extends State<CampoNomeRemedio> {
  static const _espera = Duration(milliseconds: 350);
  static const _maximoSugestoes = 6;

  Timer? _temporizador;
  int _pedidoAtual = 0; // descarta respostas antigas que chegam atrasadas
  List<MedicamentoCatalogo> _sugestoes = [];
  bool _buscando = false;
  bool _aberto = false;
  String? _aviso;
  String _ultimoEscolhido = '';

  @override
  void initState() {
    super.initState();
    // Se a lista ainda não ficou pronta (servidor acordando), tenta de novo.
    ApiMedCerto.instance.prepararCatalogo(recomecar: true);
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _fechar() {
    _pedidoAtual++;
    _temporizador?.cancel();
    setState(() {
      _aberto = false;
      _buscando = false;
      _sugestoes = [];
      _aviso = null;
    });
  }

  void _aoDigitar(String texto) {
    widget.onChanged?.call(texto);
    final termo = normalizarBusca(texto);
    if (termo.length < kMinimoLetrasBusca ||
        termo == normalizarBusca(_ultimoEscolhido)) {
      _fechar();
      return;
    }
    _temporizador?.cancel();
    setState(() {
      _aberto = true;
      _buscando = true;
      _aviso = null;
    });
    _temporizador = Timer(_espera, () => _buscar(termo));
  }

  Future<void> _buscar(String termo) async {
    final pedido = ++_pedidoAtual;
    String? aviso;
    var resultado = <MedicamentoCatalogo>[];
    try {
      resultado = await ApiMedCerto.instance.buscar(termo);
      if (resultado.isEmpty) {
        aviso = 'Não achei esse nome na lista. Pode continuar digitando normalmente.';
      }
    } on ApiErro catch (e) {
      aviso = e.semConexao
          ? 'Sem conexão com a lista de remédios. Pode digitar o nome normalmente.'
          : '${e.mensagem} Pode digitar o nome normalmente.';
    } catch (_) {
      aviso = 'Não consegui buscar agora. Pode digitar o nome normalmente.';
    }
    if (!mounted || pedido != _pedidoAtual) return;
    setState(() {
      _buscando = false;
      _sugestoes = resultado.take(_maximoSugestoes).toList();
      _aviso = aviso;
    });
  }

  void _escolher(MedicamentoCatalogo m) {
    final nome = m.nomeExibicao;
    _ultimoEscolhido = nome;
    widget.controller.value = TextEditingValue(
      text: nome,
      selection: TextSelection.collapsed(offset: nome.length),
    );
    widget.onChanged?.call(nome);
    widget.onEscolher?.call(m);
    _fechar();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'Comece a digitar. Ex.: Metformina',
            errorText: widget.erro,
            suffixIcon: _buscando
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : const Icon(Icons.search, size: 28),
          ),
          onChanged: _aoDigitar,
        ),
        if (!_aberto) const _SituacaoDaLista(),
        if (_aberto) ...[
          const SizedBox(height: 8),
          _Painel(
            buscando: _buscando,
            sugestoes: _sugestoes,
            aviso: _aviso,
            onEscolher: _escolher,
            onFechar: _fechar,
          ),
        ],
      ],
    );
  }
}

class _Painel extends StatelessWidget {
  final bool buscando;
  final List<MedicamentoCatalogo> sugestoes;
  final String? aviso;
  final ValueChanged<MedicamentoCatalogo> onEscolher;
  final VoidCallback onFechar;

  const _Painel({
    required this.buscando,
    required this.sugestoes,
    required this.aviso,
    required this.onEscolher,
    required this.onFechar,
  });

  @override
  Widget build(BuildContext context) {
    final contraste = altoContraste(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: contraste ? Colors.black : Cores.dourado,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sugestoes.isNotEmpty
                        ? 'Toque no nome do seu remédio:'
                        : (buscando ? 'Procurando na lista…' : 'Lista de remédios'),
                    style: TextStyle(fontSize: 15, color: corSuave(context)),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar sugestões',
                  onPressed: onFechar,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          for (final m in sugestoes) _Sugestao(remedio: m, onTap: () => onEscolher(m)),
          if (sugestoes.isEmpty && aviso != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Cores.marrom),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(aviso!,
                        style: const TextStyle(fontSize: 16, color: Cores.marrom)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Sugestao extends StatelessWidget {
  final MedicamentoCatalogo remedio;
  final VoidCallback onTap;
  const _Sugestao({required this.remedio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final detalhe = remedio.detalhe;
    return Semantics(
      button: true,
      label: 'Escolher ${remedio.nomeExibicao}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Cores.rosaClaro)),
          ),
          child: Row(
            children: [
              const Icon(Icons.medication_outlined, color: Cores.vinho, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(remedio.nomeExibicao,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    if (detalhe.isNotEmpty)
                      Text(detalhe,
                          style: TextStyle(fontSize: 14, color: corSuave(context))),
                  ],
                ),
              ),
              const Icon(Icons.north_west, color: Cores.textoSuave),
            ],
          ),
        ),
      ),
    );
  }
}


/// Aviso discreto, embaixo do campo, sobre a lista de remédios do servidor.
/// O servidor gratuito "dorme" e pode levar até 1 minuto para acordar.
class _SituacaoDaLista extends StatelessWidget {
  const _SituacaoDaLista();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EstadoCatalogo>(
      valueListenable: estadoCatalogo,
      builder: (context, estado, _) {
        final suave = corSuave(context);
        final Widget icone;
        final String texto;
        switch (estado) {
          case EstadoCatalogo.disponivel:
            icone = const Icon(Icons.check_circle_outline, size: 18, color: Cores.verde);
            texto = 'Lista de remédios disponível';
          case EstadoCatalogo.verificando:
            icone = SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: suave),
            );
            texto = 'Carregando a lista de remédios…';
          case EstadoCatalogo.indisponivel:
            icone = Icon(Icons.cloud_off_outlined, size: 18, color: suave);
            texto = 'Lista de remédios indisponível agora. Pode digitar o nome normalmente.';
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Row(
              key: ValueKey(estado),
              children: [
                icone,
                const SizedBox(width: 8),
                Expanded(
                  child: Text(texto, style: TextStyle(fontSize: 14, color: suave)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
