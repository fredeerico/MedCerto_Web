import '../utils/datas.dart';
import '../utils/validacao.dart';

class Medicamento {
  final int? id;
  final String nome;
  final String dose; // "850 mg"
  final int quantidade; // comprimidos por dose
  final String observacao; // "depois do almoço"
  final List<String> horarios; // ["08:00", "20:00"]
  final bool todoDia;
  final List<int> dias; // 1 = segunda ... 7 = domingo (DateTime.weekday)
  final int estoque; // comprimidos que ainda restam
  final int caixa; // tamanho da caixa (0 = não informado)
  final bool ativo;
  final int cor; // índice da cor da pílula
  final String criadoEm; // "2026-10-23"

  const Medicamento({
    this.id,
    required this.nome,
    required this.dose,
    this.quantidade = 1,
    this.observacao = '',
    required this.horarios,
    this.todoDia = true,
    this.dias = const [],
    this.estoque = 0,
    this.caixa = 0,
    this.ativo = true,
    this.cor = 0,
    this.criadoEm = '',
  });

  String get nomeCompleto => dose.isEmpty ? nome : '$nome $dose';

  String get textoQuantidade =>
      quantidade == 1 ? '1 comprimido' : '$quantidade comprimidos';

  String get textoDias {
    if (todoDia) return 'Todo dia';
    final ordenados = [...dias]..sort();
    return ordenados.map((d) => diasCurtos[d - 1]).join(', ');
  }

  /// Este remédio deve ser tomado nesta data?
  bool tomaNoDia(DateTime dia) {
    if (!ativo) return false;
    if (criadoEm.isNotEmpty && dataChave(dia).compareTo(criadoEm) < 0) {
      return false;
    }
    return todoDia || dias.contains(dia.weekday);
  }

  int? get diasRestantes => calcularDiasRestantes(
        estoque: caixa > 0 ? estoque : null,
        quantidade: quantidade,
        dosesPorDia: horarios.length,
        diasPorSemana: todoDia ? 7 : dias.length,
      );

  Medicamento copyWith({
    int? id,
    String? nome,
    String? dose,
    int? quantidade,
    String? observacao,
    List<String>? horarios,
    bool? todoDia,
    List<int>? dias,
    int? estoque,
    int? caixa,
    bool? ativo,
    int? cor,
    String? criadoEm,
  }) =>
      Medicamento(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        dose: dose ?? this.dose,
        quantidade: quantidade ?? this.quantidade,
        observacao: observacao ?? this.observacao,
        horarios: horarios ?? this.horarios,
        todoDia: todoDia ?? this.todoDia,
        dias: dias ?? this.dias,
        estoque: estoque ?? this.estoque,
        caixa: caixa ?? this.caixa,
        ativo: ativo ?? this.ativo,
        cor: cor ?? this.cor,
        criadoEm: criadoEm ?? this.criadoEm,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'nome': nome,
        'dose': dose,
        'quantidade': quantidade,
        'observacao': observacao,
        'horarios': horarios.join(','),
        'todo_dia': todoDia ? 1 : 0,
        'dias': dias.join(','),
        'estoque': estoque,
        'caixa': caixa,
        'ativo': ativo ? 1 : 0,
        'cor': cor,
        'criado_em': criadoEm,
      };

  factory Medicamento.fromMap(Map<String, Object?> m) {
    List<String> textos(Object? v) => (v as String? ?? '')
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return Medicamento(
      id: m['id'] as int?,
      nome: m['nome'] as String? ?? '',
      dose: m['dose'] as String? ?? '',
      quantidade: m['quantidade'] as int? ?? 1,
      observacao: m['observacao'] as String? ?? '',
      horarios: textos(m['horarios']),
      todoDia: (m['todo_dia'] as int? ?? 1) == 1,
      dias: textos(m['dias']).map(int.parse).toList(),
      estoque: m['estoque'] as int? ?? 0,
      caixa: m['caixa'] as int? ?? 0,
      ativo: (m['ativo'] as int? ?? 1) == 1,
      cor: m['cor'] as int? ?? 0,
      criadoEm: m['criado_em'] as String? ?? '',
    );
  }
}

/// Uma dose confirmada ("Já tomei").
class RegistroDose {
  final int medId;
  final String data; // "2026-10-23"
  final String horario; // "08:00"
  const RegistroDose(this.medId, this.data, this.horario);

  factory RegistroDose.fromMap(Map<String, Object?> m) => RegistroDose(
        m['med_id'] as int,
        m['data'] as String,
        m['horario'] as String,
      );
}
