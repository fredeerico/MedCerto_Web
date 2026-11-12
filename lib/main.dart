import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/alarme_screen.dart';
import 'screens/inicio_screen.dart';
import 'services/acoes.dart';
import 'services/api.dart';
import 'services/banco.dart';
import 'services/estado.dart';
import 'services/notificacoes.dart';
import 'theme/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WEB: cria os botões e textos como elementos reais da página, para leitores
  // de tela e ferramentas que gravam demonstrações a partir do link.
  WidgetsBinding.instance.ensureSemantics();

  final prefs = await Banco.instance.lerPreferencias();
  prefsNotifier.value = prefs;

  final notif = Notificacoes.instance;
  notif.vibrar = prefs.vibrar;
  notif.somAlto = prefs.somAlto;
  notif.aoResponder = tratarNotificacao;
  await notif.init();
  if (prefs.modoReserva) {
    notif.ligarReserva(() => Banco.instance.listarMedicamentos(somenteAtivos: true));
  }

  WidgetsBinding.instance.addObserver(_CicloDoApp());
  runApp(const MedCertoApp());

  // Acorda o servidor da lista de remédios (Render) em segundo plano, para
  // ela já estar pronta quando a pessoa for cadastrar um remédio.
  ApiMedCerto.instance.prepararCatalogo();

  // Se o app foi aberto pela notificação (estava fechado), trata depois
  // que a primeira tela aparecer.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      appNaFrenteDesde ??= DateTime.now();
    }
    final r = notif.consumirRespostaDeAbertura();
    final dados = Notificacoes.lerPayload(r?.payload);
    if (dados != null) tratarNotificacao(dados.$1, dados.$2, r?.actionId);
  });
}

/// Guarda quando o app foi para a frente da tela (ver [appEmUso]).
class _CicloDoApp extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      appNaFrenteDesde ??= DateTime.now();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      appNaFrenteDesde = null;
    }
  }
}

/// Toque na notificação ou em um dos botões dela.
Future<void> tratarNotificacao(int medId, String horario, String? acao) async {
  // Se o app foi aberto pelo alarme (celular bloqueado ou app fechado),
  // depois da resposta ele fecha e o celular volta para a tela de bloqueio.
  // Assim ninguém usa o app sem desbloquear o celular.
  // WEB: não existe tela de bloqueio nem como "fechar o app".
  final fecharDepois = !kIsWeb && !appEmUso;
  final m = await Banco.instance.buscarMedicamento(medId);
  if (m == null) return;
  if (acao == 'tomei' || acao == 'adiar') {
    if (acao == 'tomei') {
      await Acoes.tomar(m, horario);
    } else {
      await Acoes.adiar(m, horario);
    }
    if (fecharDepois) await SystemNavigator.pop();
  } else {
    // Toque na notificação em si: abre a tela "Hora do remédio" (sem PIN,
    // para o idoso responder rápido).
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => AlarmeScreen(
        medId: medId,
        horario: horario,
        fecharAppAoTerminar: fecharDepois,
      ),
    ));
  }
}

class MedCertoApp extends StatelessWidget {
  const MedCertoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: prefsNotifier,
      builder: (context, prefs, _) => MaterialApp(
        title: 'MedCerto',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: mensageiroKey,
        theme: AppTema.claro(altoContraste: prefs.altoContraste),
        // Tamanho da letra escolhido no Perfil vale para o app inteiro.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(prefs.escalaTexto)),
          child: child!,
        ),
        home: const InicioScreen(),
      ),
    );
  }
}
