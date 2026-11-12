/// Funções de data e horário usadas em todo o app (sem pacotes externos).
library;

const diasCurtos = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const iniciaisDias = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
const meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

String doisDigitos(int n) => n.toString().padLeft(2, '0');

/// 2026-10-23
String dataChave(DateTime d) =>
    '${d.year}-${doisDigitos(d.month)}-${doisDigitos(d.day)}';

/// 08:05
String hhmm(int hora, int minuto) =>
    '${doisDigitos(hora)}:${doisDigitos(minuto)}';
String hhmmDe(DateTime d) => hhmm(d.hour, d.minute);

/// "08:05" -> (8, 5)
(int, int) lerHorario(String horario) {
  final partes = horario.split(':');
  return (int.parse(partes[0]), int.parse(partes[1]));
}

DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime noDia(DateTime dia, String horario) {
  final (h, m) = lerHorario(horario);
  return DateTime(dia.year, dia.month, dia.day, h, m);
}

/// "Sex, 23 de outubro"
String dataPorExtenso(DateTime d) =>
    '${diasCurtos[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';

String saudacao(DateTime d) {
  if (d.hour < 12) return 'Bom dia';
  if (d.hour < 18) return 'Boa tarde';
  return 'Boa noite';
}
