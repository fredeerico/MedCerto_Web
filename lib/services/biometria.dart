enum ResultadoDigital { ok, cancelado, indisponivel, semCadastro, bloqueado, erro }

/// VERSÃO WEB: o navegador não tem leitor de digital.
///
/// No app Android este arquivo usa o pacote local_auth. Aqui ele mantém os
/// mesmos nomes, para as telas ficarem iguais às do app, mas sempre responde
/// "indisponível" — a pessoa entra pelo PIN.
class Biometria {
  Biometria._();
  static final Biometria instance = Biometria._();

  Future<bool> disponivel() async => false;

  Future<ResultadoDigital> entrar() async => ResultadoDigital.indisponivel;

  /// Mensagem simples para mostrar ao usuário (null = não mostra nada).
  static String? mensagem(ResultadoDigital r) => switch (r) {
        ResultadoDigital.ok || ResultadoDigital.cancelado => null,
        ResultadoDigital.indisponivel =>
          'A entrada pela digital só funciona no aplicativo do celular. Use o PIN.',
        ResultadoDigital.semCadastro =>
          'Nenhuma digital cadastrada no celular. Use o PIN.',
        ResultadoDigital.bloqueado =>
          'Muitas tentativas com a digital. Use o PIN.',
        ResultadoDigital.erro =>
          'Não foi possível usar a digital agora. Use o PIN.',
      };
}
