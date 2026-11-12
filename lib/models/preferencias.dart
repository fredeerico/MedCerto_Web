class Preferencias {
  final String nome;
  final String pin;
  final int tamanhoLetra; // 0 pequena, 1 normal, 2 grande
  final bool altoContraste;
  final bool vibrar;
  final bool somAlto; // usa o volume de ALARME e repete o som
  final bool modoReserva; // Timer dentro do app, além do agendamento nativo

  const Preferencias({
    this.nome = '',
    this.pin = '',
    this.tamanhoLetra = 1,
    this.altoContraste = false,
    this.vibrar = true,
    this.somAlto = true,
    this.modoReserva = false,
  });

  String get inicial =>
      nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase();

  double get escalaTexto => const [0.9, 1.0, 1.2][tamanhoLetra.clamp(0, 2)];

  Preferencias copyWith({
    String? nome,
    String? pin,
    int? tamanhoLetra,
    bool? altoContraste,
    bool? vibrar,
    bool? somAlto,
    bool? modoReserva,
  }) =>
      Preferencias(
        nome: nome ?? this.nome,
        pin: pin ?? this.pin,
        tamanhoLetra: tamanhoLetra ?? this.tamanhoLetra,
        altoContraste: altoContraste ?? this.altoContraste,
        vibrar: vibrar ?? this.vibrar,
        somAlto: somAlto ?? this.somAlto,
        modoReserva: modoReserva ?? this.modoReserva,
      );

  Map<String, String> toMap() => {
        'nome': nome,
        'pin': pin,
        'tamanho_letra': '$tamanhoLetra',
        'alto_contraste': altoContraste ? '1' : '0',
        'vibrar': vibrar ? '1' : '0',
        'som_alto': somAlto ? '1' : '0',
        'modo_reserva': modoReserva ? '1' : '0',
      };

  factory Preferencias.fromMap(Map<String, String> m) => Preferencias(
        nome: m['nome'] ?? '',
        pin: m['pin'] ?? '',
        tamanhoLetra: int.tryParse(m['tamanho_letra'] ?? '') ?? 1,
        altoContraste: m['alto_contraste'] == '1',
        vibrar: m['vibrar'] != '0',
        somAlto: m['som_alto'] != '0',
        modoReserva: m['modo_reserva'] == '1',
      );
}
