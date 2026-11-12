// Testes unitários das regras de validação e cálculo (evidência da RT03).
// Rodar com:  flutter test
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/utils/datas.dart';
import 'package:flutter_application_1/utils/validacao.dart';

ResultadoValidacao _valido({
  String nome = 'Metformina',
  String dose = '850 mg',
  int quantidade = 1,
  List<String> horarios = const ['08:00'],
  bool todoDia = true,
  List<int> dias = const [],
  String estoque = '',
}) =>
    validarMedicamento(
      nome: nome,
      dose: dose,
      quantidade: quantidade,
      horarios: horarios,
      todoDia: todoDia,
      dias: dias,
      estoque: estoque,
    );

void main() {
  group('validarMedicamento', () {
    test('aceita um cadastro completo', () {
      expect(_valido().ok, isTrue);
    });

    test('recusa nome vazio ou só com espaços', () {
      expect(_valido(nome: '   ').erros.containsKey('nome'), isTrue);
    });

    test('recusa nome com uma letra só', () {
      expect(_valido(nome: 'A').erros['nome'], contains('curto'));
    });

    test('aceita dose vazia (é opcional)', () {
      expect(_valido(dose: '').ok, isTrue);
    });

    test('recusa dose sem número', () {
      expect(_valido(dose: 'muito').erros.containsKey('dose'), isTrue);
    });

    test('recusa quantidade fora de 1 a 10', () {
      expect(_valido(quantidade: 0).erros.containsKey('quantidade'), isTrue);
      expect(_valido(quantidade: 11).erros.containsKey('quantidade'), isTrue);
    });

    test('exige pelo menos um horário', () {
      expect(_valido(horarios: []).erros.containsKey('horarios'), isTrue);
    });

    test('recusa horário inválido', () {
      expect(_valido(horarios: ['25:00']).erros.containsKey('horarios'), isTrue);
    });

    test('recusa horários repetidos', () {
      expect(_valido(horarios: ['08:00', '08:00']).erros.containsKey('horarios'),
          isTrue);
    });

    test('"Alguns dias" exige escolher pelo menos um dia', () {
      expect(_valido(todoDia: false).erros.containsKey('dias'), isTrue);
      expect(_valido(todoDia: false, dias: [1, 3]).ok, isTrue);
    });

    test('estoque precisa ser número entre 0 e 999', () {
      expect(_valido(estoque: 'abc').erros.containsKey('estoque'), isTrue);
      expect(_valido(estoque: '-1').erros.containsKey('estoque'), isTrue);
      expect(_valido(estoque: '30').ok, isTrue);
    });
  });

  group('horários', () {
    test('horarioValido', () {
      expect(horarioValido('08:00'), isTrue);
      expect(horarioValido('23:59'), isTrue);
      expect(horarioValido('8:00'), isFalse);
      expect(horarioValido('24:00'), isFalse);
      expect(horarioValido('12:60'), isFalse);
    });

    test('ordenarHorarios ordena e remove repetidos', () {
      expect(ordenarHorarios(['20:00', '08:00', '20:00']), ['08:00', '20:00']);
    });

    test('lerHorario e hhmm', () {
      expect(lerHorario('07:05'), (7, 5));
      expect(hhmm(7, 5), '07:05');
    });
  });

  group('normalizarDose', () {
    test('separa número e unidade', () {
      expect(normalizarDose('850mg'), '850 mg');
      expect(normalizarDose(' 20 MG '), '20 mg');
      expect(normalizarDose('2,5ml'), '2,5 ml');
    });

    test('mantém texto livre', () {
      expect(normalizarDose('1 gota em cada olho'), '1 gota em cada olho');
    });
  });

  group('validarPin', () {
    test('aceita 4 números', () => expect(validarPin('1234'), isNull));
    test('recusa letras ou tamanho errado', () {
      expect(validarPin('12a4'), isNotNull);
      expect(validarPin('123'), isNotNull);
      expect(validarPin('12345'), isNotNull);
    });
  });

  group('calcularDiasRestantes', () {
    test('30 comprimidos, 1 por dose, 2 vezes ao dia = 15 dias', () {
      expect(
          calcularDiasRestantes(
              estoque: 30, quantidade: 1, dosesPorDia: 2, diasPorSemana: 7),
          15);
    });

    test('estoque não informado devolve null', () {
      expect(
          calcularDiasRestantes(
              estoque: null, quantidade: 1, dosesPorDia: 2, diasPorSemana: 7),
          isNull);
    });

    test('estoque zerado devolve 0', () {
      expect(
          calcularDiasRestantes(
              estoque: 0, quantidade: 1, dosesPorDia: 1, diasPorSemana: 7),
          0);
    });

    test('só alguns dias da semana dura mais', () {
      // 6 comprimidos, 1 por dia, 3 dias por semana = 14 dias
      expect(
          calcularDiasRestantes(
              estoque: 6, quantidade: 1, dosesPorDia: 1, diasPorSemana: 3),
          14);
    });
  });

  group('percentual', () {
    test('calcula e arredonda', () {
      expect(percentual(2, 3), 67);
      expect(percentual(5, 5), 100);
    });
    test('sem doses previstas = 100%', () => expect(percentual(0, 0), 100));
  });

  group('dose com unidade', () {
    test('montarDose junta número e unidade', () {
      expect(montarDose('850', 'mg'), '850 mg');
      expect(montarDose(' 5 ', 'ml'), '5 ml');
      expect(montarDose('', 'mg'), '');
      expect(montarDose('1 gota', 'mg'), '1 gota');
    });

    test('separarDose reconhece mg, g e ml', () {
      expect(separarDose('850 mg'), ('850', 'mg'));
      expect(separarDose('2,5ml'), ('2,5', 'ml'));
      expect(separarDose('1 g'), ('1', 'g'));
      expect(separarDose('1 gota'), ('1 gota', 'mg'));
    });
  });
}
