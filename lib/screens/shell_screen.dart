import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/banco.dart';
import '../services/estado.dart';
import '../services/notificacoes.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/layout_web.dart';
import 'adicionar_screen.dart';
import 'hoje_screen.dart';
import 'perfil_screen.dart';
import 'remedios_screen.dart';

/// Esqueleto com a barra inferior: Hoje · Remédios · Adicionar · Perfil.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  @override
  void initState() {
    super.initState();
    abaAtual.value = 0;
    // Pede as permissões depois que a tela aparece (Android 13+).
    WidgetsBinding.instance.addPostFrameCallback((_) => _permissoes());
  }

  static const _chaveTelaCheia = 'pediu_tela_cheia';

  Future<void> _permissoes() async {
    if (kIsWeb) return; // WEB: o navegador não tem essas permissões.
    await Notificacoes.instance.pedirPermissoes();
    // Android 14+: sem a permissão "tela cheia", o alarme vira só uma
    // notificação comum e a tela "Você já tomou?" não abre sozinha.
    // Explica uma vez e abre o ajuste; se já estiver liberado, nada aparece.
    if (await Banco.instance.lerChave(_chaveTelaCheia) == '1') return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.alarm, size: 36),
        title: const Text('Mostrar o alarme na tela'),
        content: const Text(
          'Para a tela do remédio aparecer sozinha na hora certa, mesmo com o '
          'celular bloqueado, ative "Permitir" na próxima tela e volte.',
          style: TextStyle(fontSize: 17, height: 1.35),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
    await Banco.instance.salvarChave(_chaveTelaCheia, '1');
    await Notificacoes.instance.pedirTelaCheia();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: abaAtual,
      builder: (context, aba, _) {
        final computador = telaDeComputador(context);
        return Scaffold(
          body: Row(
            children: [
              // Computador: menu na lateral. Celular: barra embaixo.
              if (computador)
                MenuLateral(indice: aba, aoTocar: (i) => abaAtual.value = i),
              Expanded(
                key: const ValueKey('conteudo'),
                child: ColunaWeb(
                  fundo: Theme.of(context).scaffoldBackgroundColor,
                  child: IndexedStack(
                    index: aba,
                    children: const [
                      HojeScreen(),
                      RemediosScreen(),
                      AdicionarScreen(),
                      PerfilScreen(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: computador
              ? null
              : BarraInferior(
                  indice: aba,
                  aoTocar: (i) => abaAtual.value = i,
                ),
        );
      },
    );
  }
}
