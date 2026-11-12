// Teste de widget da barra inferior (substitui o teste padrão do contador,
// que procurava um "MyApp" que não existe mais e quebrava o `flutter test`).
import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/barra_inferior.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('barra inferior mostra as 4 abas e avisa qual foi tocada',
      (tester) async {
    int? tocada;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: BarraInferior(indice: 0, aoTocar: (i) => tocada = i),
      ),
    ));

    for (final rotulo in ['Hoje', 'Remédios', 'Adicionar', 'Perfil']) {
      expect(find.text(rotulo), findsOneWidget);
    }

    await tester.tap(find.text('Adicionar'));
    expect(tocada, 2);
  });

  testWidgets('barra inferior não cobre a tela (bug corrigido)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: BarraInferior(indice: 0, aoTocar: (_) {}),
      ),
    ));
    final altura = tester.getSize(find.byType(BarraInferior)).height;
    expect(altura, lessThan(150));
  });
}
