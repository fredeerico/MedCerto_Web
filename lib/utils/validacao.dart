/// Regras de validação e cálculos "puros" (sem Flutter), para poderem ser
/// testados com `flutter test` — evidência de usabilidade da RT03
/// (heurísticas H5 Prevenção de erros e H9 Recuperação de erros).
library;

class ResultadoValidacao {
  final Map<String, String> erros;
  const ResultadoValidacao(this.erros);
  bool get ok => erros.isEmpty;
}

final _regexHorario = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

bool horarioValido(String horario) => _regexHorario.hasMatch(horario);

/// Ordena "20:00", "08:00" -> ["08:00", "20:00"] e remove repetidos.
List<String> ordenarHorarios(Iterable<String> horarios) {
  final lista = horarios.toSet().toList()..sort();
  return lista;
}

/// "850mg" -> "850 mg"; "  20 MG " -> "20 mg"; texto livre fica como está.
String normalizarDose(String dose) {
  final limpo = dose.trim();
  final m = RegExp(r'^(\d+(?:[.,]\d+)?)\s*([a-zA-Zµ]+)$').firstMatch(limpo);
  if (m == null) return limpo;
  return '${m.group(1)} ${m.group(2)!.toLowerCase()}';
}

/// Unidades oferecidas no cadastro.
const unidadesDose = ['mg', 'g', 'ml'];

/// Junta o número digitado com a unidade escolhida: ("850", "mg") -> "850 mg".
/// Campo vazio -> "" (dose é opcional). Se a pessoa já escreveu a unidade
/// ou um texto ("1 gota"), mantém o que ela escreveu.
String montarDose(String quantidade, String unidade) {
  final t = quantidade.trim();
  if (t.isEmpty) return '';
  if (RegExp(r'[a-zA-Zµ]').hasMatch(t)) return normalizarDose(t);
  return '$t $unidade';
}

/// Separa uma dose salva em número e unidade: "850 mg" -> ("850", "mg").
/// Se não reconhecer a unidade, devolve o texto inteiro e "mg".
(String, String) separarDose(String dose) {
  final m = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(mg|g|ml)?\s*$', caseSensitive: false)
      .firstMatch(dose);
  if (m == null) return (dose.trim(), 'mg');
  return (m.group(1)!, (m.group(2) ?? 'mg').toLowerCase());
}

ResultadoValidacao validarMedicamento({
  required String nome,
  required String dose,
  required int quantidade,
  required List<String> horarios,
  required bool todoDia,
  required List<int> dias,
  required String estoque,
}) {
  final erros = <String, String>{};
  final n = nome.trim();

  if (n.isEmpty) {
    erros['nome'] = 'Escreva o nome do remédio.';
  } else if (n.length < 2) {
    erros['nome'] = 'O nome está muito curto.';
  } else if (n.length > 60) {
    erros['nome'] = 'O nome está muito longo (máximo 60 letras).';
  }

  // A dose é opcional; se for preenchida, precisa ter um número.
  final d = dose.trim();
  if (d.isNotEmpty && !RegExp(r'\d').hasMatch(d)) {
    erros['dose'] = 'A dose precisa ter um número. Ex.: 850';
  }

  if (quantidade < 1 || quantidade > 10) {
    erros['quantidade'] = 'A quantidade deve ser entre 1 e 10.';
  }

  if (horarios.isEmpty) {
    erros['horarios'] = 'Escolha pelo menos um horário.';
  } else if (horarios.any((h) => !horarioValido(h))) {
    erros['horarios'] = 'Há um horário inválido.';
  } else if (horarios.toSet().length != horarios.length) {
    erros['horarios'] = 'Há horários repetidos.';
  }

  if (!todoDia && dias.isEmpty) {
    erros['dias'] = 'Escolha em quais dias você toma.';
  } else if (dias.any((x) => x < 1 || x > 7)) {
    erros['dias'] = 'Dia da semana inválido.';
  }

  final e = estoque.trim();
  if (e.isNotEmpty) {
    final valor = int.tryParse(e);
    if (valor == null || valor < 0 || valor > 999) {
      erros['estoque'] = 'Use um número entre 0 e 999.';
    }
  }

  return ResultadoValidacao(erros);
}

/// PIN precisa ter exatamente 4 números.
String? validarPin(String pin) {
  if (!RegExp(r'^\d{4}$').hasMatch(pin)) return 'O PIN deve ter 4 números.';
  return null;
}

/// Quantos dias o estoque ainda dura. `null` quando o estoque não foi
/// informado ou o remédio não tem horários.
int? calcularDiasRestantes({
  required int? estoque,
  required int quantidade,
  required int dosesPorDia,
  required int diasPorSemana,
}) {
  if (estoque == null ||
      quantidade <= 0 ||
      dosesPorDia <= 0 ||
      diasPorSemana <= 0) {
    return null;
  }
  if (estoque <= 0) return 0;
  final consumoPorSemana = quantidade * dosesPorDia * diasPorSemana;
  return (estoque * 7 / consumoPorSemana).floor();
}

/// Percentual de doses tomadas (0 a 100). Sem doses previstas = 100%.
int percentual(int feitas, int previstas) {
  if (previstas <= 0) return 100;
  return ((feitas * 100) / previstas).round().clamp(0, 100);
}
