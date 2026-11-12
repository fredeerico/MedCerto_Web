import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/medicamento_catalogo.dart';
import '../utils/busca.dart';
import 'banco.dart';

/// Endereço do back (Django) publicado no Render.
const String kApiUrl = 'https://medcerto-api.onrender.com';

/// Situação da lista de remédios (catálogo) no servidor.
enum EstadoCatalogo { verificando, disponivel, indisponivel }

/// As telas escutam isto para mostrar um aviso discreto quando a lista de
/// remédios fica pronta para uso.
final estadoCatalogo = ValueNotifier<EstadoCatalogo>(EstadoCatalogo.verificando);

class ApiErro implements Exception {
  final String mensagem;
  final bool semConexao;
  const ApiErro(this.mensagem, {this.semConexao = false});

  @override
  String toString() => mensagem;
}

/// Conversa com o back (Django REST Framework, repositório app-medcerto).
///
/// Rotas usadas (nenhuma mudança no back foi necessária):
///   POST /api/users/        cria uma conta para este aparelho (só na 1ª vez)
///   POST /api/login/        devolve o token
///   GET  /api/medications/?name=<trecho>&page=<n>   busca no catálogo
///
/// A busca exige login (IsAuthenticated). Para o idoso não precisar criar
/// conta nem senha, o app cria sozinho uma conta interna e guarda o token.
class ApiMedCerto {
  ApiMedCerto._();
  static final ApiMedCerto instance = ApiMedCerto._();

  static const _chaveToken = 'api_token';
  static const _chaveUsuario = 'api_usuario';
  static const _chaveSenha = 'api_senha';

  /// O servidor gratuito do Render "dorme" depois de 15 min parado e leva
  /// até ~1 min para acordar na primeira chamada.
  static const _tempoLimite = Duration(seconds: 70);

  /// Tentativas de acordar o servidor ao abrir o app (a cada 20 s).
  static const _maximoTentativas = 15;

  /// O back devolve 20 por página e já coloca primeiro os nomes que
  /// COMEÇAM com o termo. Por isso basta a 1ª página: uma só chamada por
  /// busca, o que deixa as sugestões bem mais rápidas no Render gratuito.
  static const _tamanhoPagina = 20;
  static const _maximoPaginas = 1;

  final http.Client _cliente = http.Client();
  String? _token;
  Future<String>? _tokenEmAndamento;
  Timer? _novaTentativa;
  int _tentativas = 0;
  final Map<String, List<MedicamentoCatalogo>> _cache = {};

  Future<Uri> _uri(String caminho, [Map<String, String>? parametros]) async {
    final base = Uri.parse('$kApiUrl$caminho');
    return parametros == null ? base : base.replace(queryParameters: parametros);
  }

  // ------------------------------------------------------------------
  // Envio e tratamento de erros
  // ------------------------------------------------------------------

  static const _cabecalhosJson = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<http.Response> _enviar(Future<http.Response> Function() pedido) async {
    try {
      return await pedido().timeout(_tempoLimite);
    } on TimeoutException {
      throw const ApiErro('O servidor demorou para responder.', semConexao: true);
    } on http.ClientException {
      throw const ApiErro('Sem conexão com o servidor.', semConexao: true);
    }
  }

  /// O back manda "application/json" sem charset; decodificamos como UTF-8
  /// na mão para os acentos (Ç, Ã, Á) não virarem símbolos estranhos.
  Map<String, dynamic> _json(http.Response r) {
    try {
      final dados = jsonDecode(utf8.decode(r.bodyBytes));
      if (dados is Map<String, dynamic>) return dados;
    } on FormatException {
      // cai no erro abaixo
    }
    throw ApiErro('Resposta inesperada do servidor (${r.statusCode}).');
  }

  // ------------------------------------------------------------------
  // Conta automática do aparelho
  // ------------------------------------------------------------------

  /// Garante um só login/cadastro por vez (o aquecimento e a busca podem
  /// pedir o token ao mesmo tempo).
  Future<String> _obterToken({bool renovar = false}) {
    final emAndamento = _tokenEmAndamento;
    if (!renovar && emAndamento != null) return emAndamento;
    final pedido = _obterTokenAgora(renovar: renovar);
    _tokenEmAndamento = pedido;
    pedido.catchError((_) => '').whenComplete(() {
      if (identical(_tokenEmAndamento, pedido)) _tokenEmAndamento = null;
    });
    return pedido;
  }

  Future<String> _obterTokenAgora({bool renovar = false}) async {
    if (!renovar) {
      _token ??= await Banco.instance.lerChave(_chaveToken);
      final atual = _token;
      if (atual != null && atual.isNotEmpty) return atual;
    }

    // Já existe conta? Só entra de novo.
    var usuario = await Banco.instance.lerChave(_chaveUsuario) ?? '';
    var senha = await Banco.instance.lerChave(_chaveSenha) ?? '';
    if (usuario.isNotEmpty && senha.isNotEmpty) {
      final token = await _entrar(usuario, senha);
      if (token != null) return _guardarToken(token);
    }

    // Primeira vez: cria uma conta interna para este aparelho.
    usuario = 'medcerto_${_aleatorio(12, 'abcdefghijkmnpqrstuvwxyz23456789')}';
    senha = _aleatorio(
        24, 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#%*-_');
    final uri = await _uri('/api/users/');
    final r = await _enviar(() => _cliente.post(
          uri,
          headers: _cabecalhosJson,
          body: jsonEncode({'username': usuario, 'password': senha}),
        ));
    if (r.statusCode != 201) {
      throw ApiErro('O servidor não aceitou criar o acesso (${r.statusCode}).');
    }
    await Banco.instance.salvarChave(_chaveUsuario, usuario);
    await Banco.instance.salvarChave(_chaveSenha, senha);

    final token = await _entrar(usuario, senha);
    if (token == null) throw const ApiErro('Não foi possível entrar no servidor.');
    return _guardarToken(token);
  }

  Future<String?> _entrar(String usuario, String senha) async {
    final uri = await _uri('/api/login/');
    final r = await _enviar(() => _cliente.post(
          uri,
          headers: _cabecalhosJson,
          body: jsonEncode({'username': usuario, 'password': senha}),
        ));
    if (r.statusCode == 200) return _json(r)['token'] as String?;
    if (r.statusCode == 401) return null; // conta não existe mais
    throw ApiErro('Erro ao entrar no servidor (${r.statusCode}).');
  }

  Future<String> _guardarToken(String token) async {
    _token = token;
    await Banco.instance.salvarChave(_chaveToken, token);
    return token;
  }

  static String _aleatorio(int tamanho, String letras) {
    final r = Random.secure();
    return List.generate(tamanho, (_) => letras[r.nextInt(letras.length)]).join();
  }

  // ------------------------------------------------------------------
  // Catálogo de remédios
  // ------------------------------------------------------------------

  Future<({int total, List<MedicamentoCatalogo> itens})> _pagina(
    String termo,
    int pagina, {
    bool jaRenovou = false,
  }) async {
    final token = await _obterToken();
    final uri = await _uri('/api/medications/', {
      if (termo.isNotEmpty) 'name': termo,
      'page': '$pagina',
    });
    final r = await _enviar(() => _cliente.get(uri, headers: {
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        }));

    if (r.statusCode == 401 && !jaRenovou) {
      // Token expirou ou a conta foi apagada no servidor: entra de novo.
      await _obterToken(renovar: true);
      return _pagina(termo, pagina, jaRenovou: true);
    }
    if (r.statusCode == 404) {
      return (total: 0, itens: <MedicamentoCatalogo>[]); // página não existe
    }
    if (r.statusCode == 400) {
      throw const ApiErro(
          'O servidor recusou o endereço. Confira ALLOWED_HOSTS no back.');
    }
    if (r.statusCode != 200) {
      throw ApiErro('Erro do servidor (${r.statusCode}).');
    }

    final dados = _json(r);
    final lista = (dados['results'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MedicamentoCatalogo.fromJson)
        .toList();
    return (total: (dados['count'] as num?)?.toInt() ?? lista.length, itens: lista);
  }

  /// Busca nomes que contêm [texto]. Devolve os mais prováveis primeiro.
  Future<List<MedicamentoCatalogo>> buscar(String texto) async {
    final termo = normalizarBusca(texto);
    if (termo.length < kMinimoLetrasBusca) return const [];
    final guardado = _cache[termo];
    if (guardado != null) return guardado;

    final primeira = await _pagina(termo, 1);
    final itens = [...primeira.itens];
    if (primeira.total > itens.length) {
      final paginas = min(_maximoPaginas, (primeira.total / _tamanhoPagina).ceil());
      final demais = await Future.wait([
        for (var p = 2; p <= paginas; p++) _pagina(termo, p),
      ]);
      for (final pagina in demais) {
        itens.addAll(pagina.itens);
      }
    }

    final ordenados = ordenarSugestoes(termo, itens);
    _cache[termo] = ordenados;
    estadoCatalogo.value = EstadoCatalogo.disponivel;
    return ordenados;
  }

  /// Acorda o servidor e confere se a lista de remédios está pronta.
  /// Chamado ao abrir o app (sem esperar) e ao abrir o cadastro.
  /// Enquanto o servidor acorda, tenta de novo a cada 20 s.
  Future<void> prepararCatalogo({bool recomecar = false}) async {
    if (estadoCatalogo.value == EstadoCatalogo.disponivel) return;
    if (recomecar) {
      if (_novaTentativa?.isActive ?? false) return; // já está tentando
      _tentativas = 0;
      estadoCatalogo.value = EstadoCatalogo.verificando;
    }
    _novaTentativa?.cancel();
    try {
      final pagina = await _pagina('', 1);
      if (pagina.total > 0) {
        estadoCatalogo.value = EstadoCatalogo.disponivel;
        return;
      }
    } catch (_) {
      // servidor ainda acordando ou sem internet: tenta de novo
    }
    _tentativas++;
    if (_tentativas < _maximoTentativas) {
      _novaTentativa = Timer(const Duration(seconds: 20), prepararCatalogo);
    } else {
      estadoCatalogo.value = EstadoCatalogo.indisponivel;
    }
  }
}
