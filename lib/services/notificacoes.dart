import 'dart:async';

import '../models/medicamento.dart';
import '../utils/datas.dart';
import 'banco.dart';

/// Minutos até a notificação "Você já tomou?" se a dose não for confirmada.
const int kMinutosAcompanhamento = 30;

/// Minutos do botão "+10 min".
const int kMinutosAdiar = 10;

typedef AoResponderNotificacao = void Function(
    int medId, String horario, String? acao);

/// Só para manter o main.dart igual ao do app.
class RespostaNotificacao {
  final String? payload;
  final String? actionId;
  const RespostaNotificacao({this.payload, this.actionId});
}

/// =========================================================================
/// VERSÃO WEB: sem notificações do sistema.
///
/// No app Android este arquivo agenda alarmes de verdade
/// (flutter_local_notifications), que tocam com o app fechado e com o
/// celular bloqueado. O navegador não faz isso.
///
/// Aqui a classe mantém os mesmos nomes, para as telas ficarem iguais às do
/// app, e faz só uma coisa: enquanto a página está ABERTA, confere o relógio
/// e, quando chega o horário de um remédio, abre a tela "Hora do remédio".
/// Assim o protótipo consegue demonstrar o fluxo principal.
/// =========================================================================
class Notificacoes {
  Notificacoes._();
  static final Notificacoes instance = Notificacoes._();

  /// Definido no main.dart: o que fazer quando chega a hora do remédio.
  AoResponderNotificacao? aoResponder;

  /// Preferências do Perfil (na web não mudam nada: não há som nem vibração).
  bool vibrar = true;
  bool somAlto = true;

  Timer? _relogio;

  /// Horários que já abriram a tela hoje ("id|data|hh:mm").
  final Set<String> _jaAvisados = {};

  /// Lembretes adiados pelo botão "+10 min": "id|hh:mm" -> quando avisar.
  final Map<String, DateTime> _adiados = {};

  Future<void> init() async {
    _relogio?.cancel();
    _relogio = Timer.periodic(const Duration(seconds: 15), (_) => _conferir());
  }

  Future<void> _conferir() async {
    final avisar = aoResponder;
    if (avisar == null) return;
    try {
      final agora = DateTime.now();
      final hoje = dataChave(agora);
      final hm = hhmmDe(agora);

      // Lembretes adiados ("+10 min").
      for (final chave in _adiados.keys.toList()) {
        if (agora.isBefore(_adiados[chave]!)) continue;
        _adiados.remove(chave);
        final dados = lerPayload(chave);
        if (dados != null) {
          avisar(dados.$1, dados.$2, null);
          return; // uma tela de cada vez
        }
      }

      // Horários normais.
      final tomadas = await Banco.instance.registrosEntre(hoje, hoje);
      for (final m in await Banco.instance.listarMedicamentos(somenteAtivos: true)) {
        final id = m.id;
        if (id == null || !m.tomaNoDia(agora) || !m.horarios.contains(hm)) {
          continue;
        }
        if (!_jaAvisados.add('$id|$hoje|$hm')) continue;
        final jaTomou = tomadas.any((r) => r.medId == id && r.horario == hm);
        if (jaTomou) continue;
        avisar(id, hm, null);
        return; // uma tela de cada vez; o próximo abre na conferência seguinte
      }
    } catch (_) {
      // Protótipo: se algo falhar aqui, a página continua funcionando.
    }
  }

  /// Usado no main.dart. Na web o app nunca é aberto por uma notificação.
  RespostaNotificacao? consumirRespostaDeAbertura() => null;

  static String criarPayload(int medId, String horario) => '$medId|$horario';

  static (int, String)? lerPayload(String? payload) {
    if (payload == null) return null;
    final partes = payload.split('|');
    if (partes.length != 2) return null;
    final id = int.tryParse(partes[0]);
    if (id == null) return null;
    return (id, partes[1]);
  }

  // ---------------------------------------------------------------------
  // Permissões: não existem no navegador.
  // ---------------------------------------------------------------------

  Future<void> pedirPermissoes() async {}
  Future<bool> notificacoesPermitidas() async => false;
  Future<bool> alarmeExatoPermitido() async => false;
  Future<void> pedirAlarmeExato() async {}
  Future<void> pedirTelaCheia() async {}

  // ---------------------------------------------------------------------
  // Agendamento: na web o "relógio" acima lê os horários direto dos
  // remédios salvos, então não há nada para agendar ou cancelar.
  // ---------------------------------------------------------------------

  Future<void> agendarMedicamento(Medicamento m) async {}

  Future<void> cancelarMedicamento(int medId) async {
    _adiados.removeWhere((chave, _) => chave.startsWith('$medId|'));
  }

  Future<void> reagendarTodos(List<Medicamento> meds) async {}

  Future<void> marcarTomado(Medicamento m, String horario, DateTime dia) async {
    if (m.id != null) _adiados.remove(criarPayload(m.id!, horario));
  }

  Future<void> desmarcarTomado(Medicamento m) async {}

  /// Botão "+10 min".
  Future<DateTime> adiar(Medicamento m, String horario) async {
    final quando = DateTime.now().add(const Duration(minutes: kMinutosAdiar));
    if (m.id != null) _adiados[criarPayload(m.id!, horario)] = quando;
    return quando;
  }

  // ---------------------------------------------------------------------
  // Modo reserva: no app é um Timer extra; na web o relógio já é isso.
  // ---------------------------------------------------------------------

  void ligarReserva(Future<List<Medicamento>> Function() carregar) {}
  void desligarReserva() {}
  bool get reservaLigada => false;
}
