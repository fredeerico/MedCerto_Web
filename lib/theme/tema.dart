import 'package:flutter/material.dart';

/// Paleta tirada das telas do Figma (vinho, dourado e creme).
class Cores {
  static const vinho = Color(0xFF7A1E2C);
  static const vinhoEscuro = Color(0xFF3E0A13);
  static const vinhoClaro = Color(0xFF8E2A3B);
  static const dourado = Color(0xFFE8B04A);
  static const creme = Color(0xFFFBF7F2);
  static const cremeAmarelo = Color(0xFFFBEFD6);
  static const rosaClaro = Color(0xFFF6E3E6);
  static const rosa = Color(0xFFE3BFC5);
  static const verdeClaro = Color(0xFFD5EDC9);
  static const verde = Color(0xFF2E6B1F);
  static const marrom = Color(0xFF5A3C00);
  static const texto = Color(0xFF2A1A1C);
  static const textoSuave = Color(0xFF6B5E60);
  static const erro = Color(0xFFB3261E);
}

/// Cor de texto secundário (fica preta no modo alto contraste).
Color corSuave(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;

/// Verdadeiro quando o usuário ligou "Alto contraste" no Perfil.
bool altoContraste(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant == Colors.black;

class AppTema {
  static ThemeData claro({bool altoContraste = false}) {
    final esquema = ColorScheme.fromSeed(seedColor: Cores.vinho).copyWith(
      primary: altoContraste ? Cores.vinhoEscuro : Cores.vinho,
      onPrimary: Colors.white,
      secondary: Cores.dourado,
      onSecondary: Cores.vinhoEscuro,
      surface: Cores.creme,
      onSurface: altoContraste ? Colors.black : Cores.texto,
      onSurfaceVariant: altoContraste ? Colors.black : Cores.textoSuave,
      error: Cores.erro,
    );

    OutlineInputBorder borda(Color cor, [double largura = 2]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cor, width: largura),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: Cores.creme,
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: esquema.onSurface,
            displayColor: esquema.onSurface,
          ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Cores.vinhoEscuro,
        actionTextColor: Cores.dourado,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: borda(Cores.vinho, altoContraste ? 3 : 2),
        enabledBorder: borda(Cores.vinho, altoContraste ? 3 : 2),
        focusedBorder: borda(Cores.dourado, 3),
        errorBorder: borda(Cores.erro, 2),
        focusedErrorBorder: borda(Cores.erro, 3),
        errorStyle: const TextStyle(fontSize: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Cores.vinho : null,
        ),
      ),
    );
  }
}
