import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/banco.dart';
import '../services/biometria.dart';
import '../services/estado.dart';
import '../theme/tema.dart';
import '../utils/validacao.dart';
import '../widgets/componentes.dart';
import '../widgets/layout_web.dart';
import 'shell_screen.dart';

/// Tela "PIN" do Figma. Também serve para CRIAR o PIN no primeiro acesso.
class PinScreen extends StatefulWidget {
  final bool criando;
  const PinScreen({super.key, this.criando = false});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _digitado = '';
  String? _primeiro; // no modo criar: PIN digitado na 1ª vez
  String? _erro;

  // WEB: o PIN também pode ser digitado no teclado do computador
  // (números, e Backspace para apagar).
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_teclaDoComputador);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_teclaDoComputador);
    super.dispose();
  }

  bool _teclaDoComputador(KeyEvent evento) {
    if (evento is! KeyDownEvent || !mounted) return false;
    // Só vale quando esta tela está na frente (não com um aviso aberto).
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    if (evento.logicalKey == LogicalKeyboardKey.backspace ||
        evento.logicalKey == LogicalKeyboardKey.delete) {
      _apagar();
      return true;
    }
    final digito = evento.character;
    if (digito != null && digito.length == 1 && '0123456789'.contains(digito)) {
      _tocar(digito);
      return true;
    }
    return false;
  }

  String get _instrucao {
    if (!widget.criando) return 'Digite seu PIN de 4 números';
    return _primeiro == null
        ? 'Crie um PIN de 4 números'
        : 'Digite o mesmo PIN de novo';
  }

  void _tocar(String digito) {
    if (_digitado.length >= 4) return;
    setState(() {
      _erro = null;
      _digitado += digito;
    });
    if (_digitado.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _conferir);
    }
  }

  void _apagar() {
    if (_digitado.isEmpty) return;
    setState(() => _digitado = _digitado.substring(0, _digitado.length - 1));
  }

  Future<void> _conferir() async {
    final pin = _digitado;
    if (validarPin(pin) != null) return;

    if (!widget.criando) {
      if (pin == prefsNotifier.value.pin) {
        _entrar();
      } else {
        setState(() {
          _erro = 'PIN errado. Tente de novo.';
          _digitado = '';
        });
      }
      return;
    }

    // Modo criar
    if (_primeiro == null) {
      setState(() {
        _primeiro = pin;
        _digitado = '';
      });
      return;
    }
    if (pin != _primeiro) {
      setState(() {
        _erro = 'Os PINs não são iguais. Vamos começar de novo.';
        _primeiro = null;
        _digitado = '';
      });
      return;
    }

    var prefs = prefsNotifier.value.copyWith(pin: pin);
    if (prefs.nome.trim().isEmpty) {
      final nome = await _perguntarNome();
      prefs = prefs.copyWith(nome: (nome == null || nome.trim().isEmpty) ? 'Você' : nome.trim());
    }
    await Banco.instance.salvarPreferencias(prefs);
    prefsNotifier.value = prefs;
    _entrar();
  }

  Future<String?> _perguntarNome() {
    final controle = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Como podemos te chamar?'),
        content: TextField(
          controller: controle,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 20),
          decoration: const InputDecoration(hintText: 'Seu nome'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controle.text),
            child: const Text('Continuar', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _entrar() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ShellScreen()),
      (_) => false,
    );
  }

  /// Tecla da digital no teclado do PIN.
  Future<void> _digital() async {
    if (widget.criando) {
      mostrarAviso('Crie o PIN primeiro. Depois você pode usar a digital.');
      return;
    }
    final resultado = await Biometria.instance.entrar();
    if (!mounted) return;
    if (resultado == ResultadoDigital.ok) {
      _entrar();
      return;
    }
    final aviso = Biometria.mensagem(resultado);
    if (aviso != null) mostrarAviso(aviso);
  }

  Future<void> _esqueci() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar um novo PIN?'),
        content: const Text(
          'Seus remédios continuam salvos. Você só vai escolher um PIN novo.',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Criar PIN novo')),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PinScreen(criando: true)),
      );
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
    final prefs = prefsNotifier.value;
    final largura = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Column(
        children: [
          // Parte de cima, vinho.
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Cores.vinho,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  top: -largura * 0.2,
                  right: -largura * 0.2,
                  child: CirculoDecorativo(
                      tamanho: largura * 0.6, cor: Cores.vinhoClaro),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BotaoVoltar(),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            AvatarInicial(widget.criando && prefs.nome.isEmpty ? '+' : prefs.inicial),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.criando ? 'Primeiro acesso' : 'Que bom te ver',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  Text(
                                    widget.criando || prefs.nome.isEmpty
                                        ? 'Vamos criar seu PIN'
                                        : 'Olá, ${prefs.nome}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(_instrucao,
                            style: const TextStyle(color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 14),
                        Semantics(
                          label: '${_digitado.length} de 4 números digitados',
                          child: Row(
                            children: [
                              for (var i = 0; i < 4; i++)
                                Container(
                                  width: 62,
                                  height: 70,
                                  margin: const EdgeInsets.only(right: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: i < _digitado.length
                                          ? Cores.dourado
                                          : Colors.white.withValues(alpha: 0.35),
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: i < _digitado.length
                                      ? const CircleAvatar(
                                          radius: 9, backgroundColor: Colors.white)
                                      : null,
                                ),
                            ],
                          ),
                        ),
                        if (_erro != null) ...[
                          const SizedBox(height: 12),
                          Etiqueta(
                            texto: _erro!,
                            icone: Icons.error_outline,
                            fundo: Colors.white,
                            cor: Cores.erro,
                            tamanhoFonte: 15,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Teclado numérico.
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 8),
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 22,
                        childAspectRatio: 1.35,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                            _Tecla(texto: d, onTap: () => _tocar(d)),
                          _Tecla(
                            icone: Icons.fingerprint,
                            rotulo: 'Digital',
                            fundo: Colors.transparent,
                            onTap: _digital,
                          ),
                          _Tecla(texto: '0', onTap: () => _tocar('0')),
                          _Tecla(
                            icone: Icons.backspace_outlined,
                            rotulo: 'Apagar',
                            fundo: Colors.transparent,
                            onTap: _apagar,
                          ),
                        ],
                      ),
                    ),
                    if (!widget.criando)
                      TextButton(
                        onPressed: _esqueci,
                        child: const Text(
                          'Esqueci meu PIN',
                          style: TextStyle(
                            fontSize: 17,
                            color: Cores.vinho,
                            decoration: TextDecoration.underline,
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
    );
  }
}

class _Tecla extends StatelessWidget {
  final String? texto;
  final IconData? icone;
  final String? rotulo;
  final Color fundo;
  final VoidCallback onTap;

  const _Tecla({
    this.texto,
    this.icone,
    this.rotulo,
    this.fundo = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: rotulo ?? texto,
      excludeSemantics: true,
      child: Material(
        color: fundo,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: texto != null
                ? Text(texto!,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Cores.vinhoEscuro))
                : Icon(icone, size: 38, color: Cores.vinhoEscuro),
          ),
        ),
      ),
    );
  }
}
