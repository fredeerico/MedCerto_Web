// Testes da busca no catálogo de remédios (autocompletar do campo Nome).
// Rodar com:  flutter test
import 'package:flutter_application_1/models/medicamento_catalogo.dart';
import 'package:flutter_application_1/utils/busca.dart';
import 'package:flutter_test/flutter_test.dart';

MedicamentoCatalogo _m(String nome) => MedicamentoCatalogo(id: 0, nome: nome);

void main() {
  group('normalizarBusca', () {
    test('tira espaços extras e põe em maiúsculas (inclusive acentos)', () {
      expect(normalizarBusca('  ação   antigripal '), 'AÇÃO ANTIGRIPAL');
      expect(normalizarBusca('metf'), 'METF');
    });
  });

  group('ordenarSugestoes', () {
    test('nome que começa com o termo vem antes (o servidor manda em ordem alfabética)', () {
      final r = ordenarSugestoes('metf', [
        _m('CLORIDRATO DE METFORMINA'),
        _m('METFORMINA'),
        _m('GLIFAGE METFORMINA XR'),
      ]);
      expect(r.first.nome, 'METFORMINA');
    });

    test('nome igual ao termo fica em primeiro', () {
      final r = ordenarSugestoes('omeprazol', [_m('OMEPRAZOL SODICO'), _m('OMEPRAZOL')]);
      expect(r.map((m) => m.nome), ['OMEPRAZOL', 'OMEPRAZOL SODICO']);
    });

    test('palavra que começa com o termo vem antes de "contém no meio"', () {
      final r = ordenarSugestoes('pir', [_m('DIPIRONA'), _m('ACIDO PIRUVICO')]);
      expect(r.first.nome, 'ACIDO PIRUVICO');
    });

    test('remove nomes repetidos e vazios', () {
      final r = ordenarSugestoes('dip', [_m('DIPIRONA'), _m('Dipirona'), _m('')]);
      expect(r.length, 1);
    });
  });

  group('nomeAmigavel', () {
    test('deixa mais fácil de ler', () {
      expect(nomeAmigavel('LOSARTANA POTÁSSICA'), 'Losartana Potássica');
      expect(nomeAmigavel('CLORIDRATO DE METFORMINA 500MG'),
          'Cloridrato de Metformina 500mg');
    });
  });

  group('MedicamentoCatalogo.fromJson', () {
    test('lê o formato da API', () {
      final m = MedicamentoCatalogo.fromJson({
        'id': 6,
        'name': 'METFORMINA',
        'stripe': 'Tarja Vermelha',
        'therapeutic_class': 'ANTIDIABETICOS',
        'anvisa_registration': '123',
      });
      expect(m.id, 6);
      expect(m.nomeExibicao, 'Metformina');
      expect(m.detalhe, 'Tarja Vermelha · Antidiabeticos');
    });

    test('aguenta campos faltando', () {
      final m = MedicamentoCatalogo.fromJson({'name': 'NOVALGINA'});
      expect(m.id, 0);
      expect(m.detalhe, '');
    });
  });
}
