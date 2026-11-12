import 'package:flutter/material.dart';

import '../models/preferencias.dart';

/// Estado global simples, sem pacotes de gerenciamento de estado.

final navigatorKey = GlobalKey<NavigatorState>();
final mensageiroKey = GlobalKey<ScaffoldMessengerState>();

/// Preferências do Perfil (tamanho da letra, contraste, etc.).
final prefsNotifier = ValueNotifier<Preferencias>(const Preferencias());

/// Aumenta sempre que algum remédio ou dose muda; as telas escutam isso
/// para recarregar.
final dadosMudaram = ValueNotifier<int>(0);
void avisarMudanca() => dadosMudaram.value++;

/// Desde quando o app está na frente da tela (null = em segundo plano).
DateTime? appNaFrenteDesde;

/// A pessoa já estava usando o app (há mais de 3 s) quando o alarme chegou?
/// Se não, o app foi aberto pelo alarme — por exemplo com o celular
/// bloqueado — e deve fechar depois da resposta, voltando à tela de bloqueio.
bool get appEmUso {
  final desde = appNaFrenteDesde;
  return desde != null &&
      DateTime.now().difference(desde) > const Duration(seconds: 3);
}

/// Aba selecionada na barra inferior (0 Hoje, 1 Remédios, 2 Adicionar, 3 Perfil).
final abaAtual = ValueNotifier<int>(0);

void mostrarAviso(String texto, {SnackBarAction? acao}) {
  final m = mensageiroKey.currentState;
  if (m == null) return;
  m.hideCurrentSnackBar();
  // WEB: no computador o aviso fica pequeno e centralizado embaixo,
  // em vez de atravessar a janela inteira.
  final computador = MediaQuery.sizeOf(m.context).width >= 800;
  m.showSnackBar(SnackBar(
    behavior: computador ? SnackBarBehavior.floating : null,
    width: computador ? 520 : null,
    content: Text(texto, style: const TextStyle(fontSize: 16)),
    action: acao,
    duration: Duration(seconds: acao == null ? 3 : 6),
  ));
}
