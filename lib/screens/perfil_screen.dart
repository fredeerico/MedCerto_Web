import 'package:flutter/material.dart';

import '../models/preferencias.dart';
import '../services/banco.dart';
import '../services/biometria.dart';
import '../services/estado.dart';
import '../services/notificacoes.dart';
import '../theme/tema.dart';
import '../widgets/componentes.dart';
import 'inicio_screen.dart';

/// Tela "Perfil" do Figma: letra, contraste, vibração, som e acompanhamento.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _salvar(Preferencias nova, {bool reagendar = false}) async {
    await Banco.instance.salvarPreferencias(nova);
    prefsNotifier.value = nova;
    final n = Notificacoes.instance;
    n.vibrar = nova.vibrar;
    n.somAlto = nova.somAlto;
    if (reagendar) {
      await n.reagendarTodos(await Banco.instance.listarMedicamentos(somenteAtivos: true));
    }
  }

  Future<void> _editarNome(BuildContext context, Preferencias p) async {
    final controle = TextEditingController(text: p.nome);
    final nome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seu nome'),
        content: TextField(
          controller: controle,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controle.text.trim()),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (nome != null && nome.isNotEmpty) await _salvar(p.copyWith(nome: nome));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Preferencias>(
      valueListenable: prefsNotifier,
      builder: (context, p, _) {
        final largura = MediaQuery.sizeOf(context).width;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabeçalho vinho
            Container(
              decoration: const BoxDecoration(
                color: Cores.vinho,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    top: -largura * 0.25,
                    right: -largura * 0.2,
                    child: CirculoDecorativo(tamanho: largura * 0.6, cor: Cores.vinhoClaro),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 20, 36),
                      child: Row(
                        children: [
                          AvatarInicial(p.inicial, tamanho: 64),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.nome.isEmpty ? 'Você' : p.nome,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800)),
                                FutureBuilder<bool>(
                                  future: Biometria.instance.disponivel(),
                                  builder: (context, digital) => Text(
                                    p.pin.isEmpty
                                        ? 'Sem PIN'
                                        : (digital.data == true
                                            ? 'PIN e digital ativos'
                                            : 'PIN ativo'),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () => _editarNome(context, p),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.25),
                              minimumSize: const Size(48, 48),
                            ),
                            child: const Text('Editar', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Cartao(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TituloSecao('Tamanho da letra'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Cores.creme,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              for (var i = 0; i < 3; i++)
                                Expanded(
                                  child: Semantics(
                                    button: true,
                                    selected: p.tamanhoLetra == i,
                                    label: const ['Letra pequena', 'Letra normal', 'Letra grande'][i],
                                    excludeSemantics: true,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _salvar(p.copyWith(tamanhoLetra: i)),
                                      child: Container(
                                        height: 56,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: p.tamanhoLetra == i ? Cores.vinho : null,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Aa',
                                          // Tamanho fixo para mostrar a diferença real.
                                          textScaler: TextScaler.noScaling,
                                          style: TextStyle(
                                            fontSize: const [16.0, 20.0, 26.0][i],
                                            fontWeight: FontWeight.w800,
                                            color: p.tamanhoLetra == i
                                                ? Colors.white
                                                : Cores.texto,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Cartao(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Column(
                      children: [
                        _LinhaOpcao(
                          icone: Icons.contrast,
                          titulo: 'Alto contraste',
                          subtitulo: 'Cores mais fortes',
                          valor: p.altoContraste,
                          onChanged: (v) => _salvar(p.copyWith(altoContraste: v)),
                        ),
                        const Divider(color: Cores.rosaClaro, height: 1),
                        _LinhaOpcao(
                          icone: Icons.vibration,
                          titulo: 'Vibrar no alarme',
                          subtitulo: 'Junto com o som',
                          valor: p.vibrar,
                          onChanged: (v) =>
                              _salvar(p.copyWith(vibrar: v), reagendar: true),
                        ),
                        const Divider(color: Cores.rosaClaro, height: 1),
                        _LinhaOpcao(
                          icone: Icons.volume_up_outlined,
                          titulo: 'Som do alarme alto',
                          subtitulo: p.somAlto
                              ? 'Usa o volume de alarme e repete até você responder'
                              : 'Som normal de notificação',
                          valor: p.somAlto,
                          onChanged: (v) =>
                              _salvar(p.copyWith(somAlto: v), reagendar: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Cartao(
                    cor: Cores.cremeAmarelo,
                    corBorda: Cores.dourado,
                    onTap: () => mostrarAviso(
                        'Em breve: convidar um familiar (depende do servidor).'),
                    child: const _LinhaLink(
                      icone: Icons.people_outline,
                      fundoIcone: Cores.dourado,
                      titulo: 'Acompanhamento',
                      subtitulo: 'Em breve: convide alguém por e-mail',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const InicioScreen()),
                      (_) => false,
                    ),
                    icon: const Icon(Icons.logout, color: Cores.vinho),
                    label: const Text('Sair',
                        style: TextStyle(fontSize: 17, color: Cores.vinho)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LinhaOpcao extends StatelessWidget {
  final IconData icone;
  final String titulo, subtitulo;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const _LinhaOpcao({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        value: valor,
        onChanged: onChanged,
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Cores.rosaClaro,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, color: Cores.vinho),
        ),
        title: Text(titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitulo, style: const TextStyle(fontSize: 15)),
      );
}

class _LinhaLink extends StatelessWidget {
  final IconData icone;
  final Color fundoIcone;
  final String titulo, subtitulo;

  const _LinhaLink({
    required this.icone,
    required this.fundoIcone,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: fundoIcone, borderRadius: BorderRadius.circular(12)),
            child: Icon(icone, color: Cores.vinhoEscuro),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(subtitulo, style: TextStyle(fontSize: 15, color: corSuave(context))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 28),
        ],
      );
}
