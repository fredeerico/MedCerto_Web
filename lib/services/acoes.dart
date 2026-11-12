import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../utils/datas.dart';
import 'banco.dart';
import 'estado.dart';
import 'notificacoes.dart';

/// Ações usadas em várias telas (e pelos botões da notificação).
class Acoes {
  /// "Já tomei": registra a dose, desconta da caixa e acerta os alarmes.
  /// Mostra aviso com "Desfazer" (H3 Controle e liberdade).
  static Future<void> tomar(Medicamento m, String horario, {DateTime? dia}) async {
    final d = dia ?? DateTime.now();
    await Banco.instance.registrarDose(m.id!, dataChave(d), horario);
    var atualizado = m;
    if (m.caixa > 0) {
      atualizado = m.copyWith(estoque: (m.estoque - m.quantidade).clamp(0, 999));
      await Banco.instance.salvarMedicamento(atualizado);
    }
    await Notificacoes.instance.marcarTomado(atualizado, horario, d);
    avisarMudanca();
    mostrarAviso(
      'Anotado: você tomou ${m.nome} das $horario.',
      acao: SnackBarAction(
        label: 'Desfazer',
        onPressed: () => desfazer(atualizado, horario, d),
      ),
    );
  }

  static Future<void> desfazer(Medicamento m, String horario, DateTime dia) async {
    await Banco.instance.removerRegistro(m.id!, dataChave(dia), horario);
    var atualizado = m;
    if (m.caixa > 0) {
      atualizado = m.copyWith(estoque: (m.estoque + m.quantidade).clamp(0, 999));
      await Banco.instance.salvarMedicamento(atualizado);
    }
    await Notificacoes.instance.desmarcarTomado(atualizado);
    avisarMudanca();
    mostrarAviso('Pronto, a dose voltou a ficar pendente.');
  }

  /// "+10 min"
  static Future<void> adiar(Medicamento m, String horario) async {
    final quando = await Notificacoes.instance.adiar(m, horario);
    mostrarAviso('Vou lembrar de novo às ${hhmmDe(quando)}.');
  }
}
