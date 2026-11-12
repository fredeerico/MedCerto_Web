import '../utils/busca.dart';

/// Um remédio do catálogo do servidor (lista PMC da ANVISA importada pelo back).
///
/// Formato que vem da API (GET /api/medications/):
/// {"id": 6, "name": "METFORMINA", "stripe": "Tarja Vermelha",
///  "therapeutic_class": "ANTIDIABETICOS", "anvisa_registration": "..."}
class MedicamentoCatalogo {
  final int id;
  final String nome; // como está no servidor (MAIÚSCULAS)
  final String tarja;
  final String classe;
  final String registro;

  const MedicamentoCatalogo({
    required this.id,
    required this.nome,
    this.tarja = '',
    this.classe = '',
    this.registro = '',
  });

  factory MedicamentoCatalogo.fromJson(Map<String, dynamic> json) =>
      MedicamentoCatalogo(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nome: (json['name'] as String? ?? '').trim(),
        tarja: (json['stripe'] as String? ?? '').trim(),
        classe: (json['therapeutic_class'] as String? ?? '').trim(),
        registro: (json['anvisa_registration'] as String? ?? '').trim(),
      );

  /// "LOSARTANA POTÁSSICA" -> "Losartana Potássica" (mais fácil de ler).
  String get nomeExibicao => nomeAmigavel(nome);

  /// Linha de apoio: "Tarja Vermelha · Antidiabeticos".
  String get detalhe => [
        if (tarja.isNotEmpty) tarja,
        if (classe.isNotEmpty) nomeAmigavel(classe),
      ].join(' · ');
}
