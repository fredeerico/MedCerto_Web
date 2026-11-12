import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/medicamento.dart';
import '../models/preferencias.dart';

/// VERSÃO WEB do banco local.
///
/// No app Android os dados ficam em SQLite (pacote sqflite), que não existe
/// no navegador. Aqui a classe tem exatamente os mesmos métodos, mas guarda
/// tudo na memória e salva uma cópia no armazenamento do navegador
/// (localStorage), para os dados continuarem lá ao recarregar a página.
/// Nada é enviado para servidor nenhum.
class Banco {
  Banco._();
  static final Banco instance = Banco._();

  static const _chaveDados = 'medcerto_dados_v1';

  SharedPreferences? _prefs;
  bool _carregado = false;

  final List<Map<String, Object?>> _medicamentos = [];
  final List<Map<String, Object?>> _registros = [];
  final Map<String, String> _preferencias = {};
  int _proximoId = 1;

  Future<void> _carregar() async {
    if (_carregado) return;
    _carregado = true;
    try {
      _prefs = await SharedPreferences.getInstance();
      final texto = _prefs?.getString(_chaveDados);
      if (texto == null || texto.isEmpty) return;
      final dados = jsonDecode(texto);
      if (dados is! Map) return;
      for (final m in (dados['medicamentos'] as List? ?? const [])) {
        if (m is Map) _medicamentos.add(Map<String, Object?>.from(m));
      }
      for (final r in (dados['registros'] as List? ?? const [])) {
        if (r is Map) _registros.add(Map<String, Object?>.from(r));
      }
      final p = dados['preferencias'];
      if (p is Map) {
        p.forEach((chave, valor) => _preferencias['$chave'] = '${valor ?? ''}');
      }
      _proximoId = (dados['proximo_id'] as num?)?.toInt() ?? 1;
      for (final m in _medicamentos) {
        final id = (m['id'] as num?)?.toInt() ?? 0;
        m['id'] = id;
        if (id >= _proximoId) _proximoId = id + 1;
      }
    } catch (_) {
      // Navegador sem armazenamento (aba anônima, por exemplo): o protótipo
      // funciona do mesmo jeito, só não lembra os dados ao recarregar.
    }
  }

  Future<void> _salvar() async {
    try {
      await _prefs?.setString(
        _chaveDados,
        jsonEncode({
          'medicamentos': _medicamentos,
          'registros': _registros,
          'preferencias': _preferencias,
          'proximo_id': _proximoId,
        }),
      );
    } catch (_) {}
  }

  // ---------------- Remédios ----------------

  Future<List<Medicamento>> listarMedicamentos({bool somenteAtivos = false}) async {
    await _carregar();
    final lista = _medicamentos
        .where((m) => !somenteAtivos || m['ativo'] == 1)
        .map(Medicamento.fromMap)
        .toList();
    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  Future<Medicamento?> buscarMedicamento(int id) async {
    await _carregar();
    for (final m in _medicamentos) {
      if (m['id'] == id) return Medicamento.fromMap(m);
    }
    return null;
  }

  /// Cria ou atualiza. Devolve o id.
  Future<int> salvarMedicamento(Medicamento m) async {
    await _carregar();
    final dados = Map<String, Object?>.from(m.toMap());
    if (m.id == null) {
      final id = _proximoId++;
      dados['id'] = id;
      _medicamentos.add(dados);
      await _salvar();
      return id;
    }
    final i = _medicamentos.indexWhere((x) => x['id'] == m.id);
    if (i >= 0) {
      _medicamentos[i] = dados;
      await _salvar();
    }
    return m.id!;
  }

  Future<void> removerMedicamento(int id) async {
    await _carregar();
    _medicamentos.removeWhere((m) => m['id'] == id);
    _registros.removeWhere((r) => r['med_id'] == id);
    await _salvar();
  }

  // ---------------- Doses tomadas ----------------

  Future<void> registrarDose(int medId, String data, String horario) async {
    await _carregar();
    final jaExiste = _registros.any((r) =>
        r['med_id'] == medId && r['data'] == data && r['horario'] == horario);
    if (jaExiste) return;
    _registros.add({
      'med_id': medId,
      'data': data,
      'horario': horario,
      'momento': DateTime.now().toIso8601String(),
    });
    await _salvar();
  }

  Future<void> removerRegistro(int medId, String data, String horario) async {
    await _carregar();
    _registros.removeWhere((r) =>
        r['med_id'] == medId && r['data'] == data && r['horario'] == horario);
    await _salvar();
  }

  /// Registros entre duas datas "aaaa-mm-dd" (inclusive).
  Future<List<RegistroDose>> registrosEntre(String inicio, String fim, {int? medId}) async {
    await _carregar();
    return _registros
        .where((r) {
          final data = r['data'] as String? ?? '';
          return data.compareTo(inicio) >= 0 &&
              data.compareTo(fim) <= 0 &&
              (medId == null || r['med_id'] == medId);
        })
        .map(RegistroDose.fromMap)
        .toList();
  }

  // ---------------- Preferências ----------------

  Future<Preferencias> lerPreferencias() async {
    await _carregar();
    return Preferencias.fromMap(Map<String, String>.from(_preferencias));
  }

  /// Valor avulso guardado junto das preferências (ex.: token da API).
  /// Devolve null quando não existe ou está vazio.
  Future<String?> lerChave(String chave) async {
    await _carregar();
    final valor = _preferencias[chave];
    return (valor == null || valor.isEmpty) ? null : valor;
  }

  Future<void> salvarChave(String chave, String valor) async {
    await _carregar();
    _preferencias[chave] = valor;
    await _salvar();
  }

  Future<void> salvarPreferencias(Preferencias p) async {
    await _carregar();
    _preferencias.addAll(p.toMap());
    await _salvar();
  }
}
