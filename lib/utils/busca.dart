// Regras da busca de nomes no catálogo (sem Flutter, para poder testar).

import '../models/medicamento_catalogo.dart';

/// A partir de quantas letras a busca começa.
const int kMinimoLetrasBusca = 2;

/// Limpa o que a pessoa digitou e põe em MAIÚSCULAS.
///
/// O servidor guarda os nomes em maiúsculas e, no SQLite, a busca só ignora
/// maiúsculas/minúsculas em letras sem acento. Mandando em maiúsculas,
/// "ação" também encontra "AÇÃO".
String normalizarBusca(String texto) => texto
    .trim()
    .split(RegExp(r'\s+'))
    .where((parte) => parte.isNotEmpty)
    .join(' ')
    .toUpperCase();

/// O servidor devolve em ordem alfabética ("CLORIDRATO DE METFORMINA" vem
/// antes de "METFORMINA"). Aqui reorganizamos para o mais provável aparecer
/// primeiro: nome igual > começa com o termo > alguma palavra começa com o
/// termo > contém o termo. Também remove nomes repetidos.
List<MedicamentoCatalogo> ordenarSugestoes(
    String termo, Iterable<MedicamentoCatalogo> itens) {
  final t = normalizarBusca(termo);

  int peso(MedicamentoCatalogo m) {
    final n = m.nome.toUpperCase();
    if (n == t) return 0;
    if (n.startsWith(t)) return 1;
    if (n.split(' ').any((palavra) => palavra.startsWith(t))) return 2;
    return 3;
  }

  final vistos = <String>{};
  final unicos = [
    for (final m in itens)
      if (m.nome.isNotEmpty && vistos.add(m.nome.toUpperCase())) m,
  ];
  unicos.sort((a, b) {
    final diferenca = peso(a) - peso(b);
    return diferenca != 0 ? diferenca : a.nome.compareTo(b.nome);
  });
  return unicos;
}

const _palavrasPequenas = {'de', 'da', 'do', 'das', 'dos', 'e', 'com', 'em'};

/// "CLORIDRATO DE METFORMINA 500MG" -> "Cloridrato de Metformina 500mg".
String nomeAmigavel(String nome) {
  final palavras = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final resultado = <String>[];
  for (var i = 0; i < palavras.length; i++) {
    final minuscula = palavras[i].toLowerCase();
    if (RegExp(r'\d').hasMatch(minuscula) ||
        (i > 0 && _palavrasPequenas.contains(minuscula))) {
      resultado.add(minuscula);
    } else {
      resultado.add(minuscula[0].toUpperCase() + minuscula.substring(1));
    }
  }
  return resultado.join(' ');
}
