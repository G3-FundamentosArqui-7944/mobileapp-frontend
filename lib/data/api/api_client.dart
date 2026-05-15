import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../config/app_config.dart';
import '../storage/token_manager.dart';
import 'api_exceptions.dart';

export 'api_exceptions.dart';

/// Cliente HTTP de BodyMatch.
///
/// - Inyecta automáticamente `Authorization: Bearer <accessToken>` en cada request.
/// - Si el backend responde 401, intenta `POST /authentication/refresh-token` con el
///   refresh almacenado y reintenta el request original una sola vez.
/// - Si el refresh falla, dispara [onSessionExpired] (el AuthBloc lo usa para cerrar sesión).
/// - Es el único punto que conoce el [TokenManager], los repositorios solo usan ApiClient.
class ApiClient {
  final TokenManager _tokenManager;
  final String _baseUrl;
  final String _refreshBaseUrl;
  final http.Client _http;

  /// Callback invocado cuando el refresh-token también falla. Configurado por AuthBloc.
  void Function()? onSessionExpired;

  /// Mutex para evitar refrescos concurrentes desde múltiples requests.
  Future<bool>? _refreshInFlight;

  /// [baseUrl] resuelve todas las peticiones del cliente. [refreshBaseUrl] es a
  /// dónde se renueva el access token cuando un 401 lo invalida; si se omite,
  /// usa el mismo [baseUrl]. En la arquitectura híbrida apuntamos siempre el
  /// refresh al IAM-service para que ambos backends compartan la misma fuente
  /// de tokens.
  ApiClient({
    required TokenManager tokenManager,
    String? baseUrl,
    String? refreshBaseUrl,
    http.Client? httpClient,
  })  : _tokenManager = tokenManager,
        _baseUrl = baseUrl ?? AppConfig.microservicesBaseUrl,
        _refreshBaseUrl = refreshBaseUrl ?? baseUrl ?? AppConfig.refreshBaseUrl,
        _http = httpClient ?? http.Client();

  // ───────────────────────────── Public API ─────────────────────────────

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) {
    return _send(
      method: 'GET',
      path: path,
      query: query,
      auth: auth,
    );
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      auth: auth,
    );
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) {
    return _send(
      method: 'PUT',
      path: path,
      body: body,
      auth: auth,
    );
  }

  Future<dynamic> delete(String path, {bool auth = true}) {
    return _send(
      method: 'DELETE',
      path: path,
      auth: auth,
    );
  }

  /// Subida multipart (video, imagen). [fields] son los `@RequestParam` no-archivo.
  Future<dynamic> uploadMultipart({
    required String path,
    required Map<String, String> fields,
    required File file,
    String fileFieldName = 'file',
    bool auth = true,
  }) async {
    Future<http.StreamedResponse> doRequest() async {
      final uri = _resolve(path, null);
      final request = http.MultipartRequest('POST', uri);
      if (auth) {
        final token = await _tokenManager.getAccessToken();
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath(
        fileFieldName,
        file.path,
        contentType: _resolveMediaType(file.path),
      ));
      return _http.send(request).timeout(AppConfig.uploadTimeout);
    }

    var streamed = await doRequest();
    if (streamed.statusCode == 401 && auth) {
      final refreshed = await _attemptRefresh();
      if (refreshed) {
        streamed = await doRequest();
      } else {
        throw SessionExpiredException();
      }
    }
    final response = await http.Response.fromStream(streamed);
    return _parse(response);
  }

  // ───────────────────────────── Internals ─────────────────────────────

  Uri _resolve(String path, Map<String, dynamic>? query) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final stringQuery = query?.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    return Uri.parse('$_baseUrl$normalized').replace(
      queryParameters: stringQuery == null || stringQuery.isEmpty ? null : stringQuery,
    );
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _tokenManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    Object? body,
    required bool auth,
  }) async {
    Future<http.Response> doRequest() async {
      final uri = _resolve(path, query);
      final headers = await _headers(auth: auth);
      final encoded = body == null ? null : jsonEncode(body);

      if (AppConfig.enableLogs) {
        // Log compacto: método + path. Nunca loguees body con datos sensibles.
        // ignore: avoid_print
        print('[API] $method $uri');
      }

      switch (method) {
        case 'GET':
          return _http.get(uri, headers: headers).timeout(AppConfig.defaultTimeout);
        case 'POST':
          return _http
              .post(uri, headers: headers, body: encoded)
              .timeout(AppConfig.defaultTimeout);
        case 'PUT':
          return _http
              .put(uri, headers: headers, body: encoded)
              .timeout(AppConfig.defaultTimeout);
        case 'DELETE':
          return _http.delete(uri, headers: headers).timeout(AppConfig.defaultTimeout);
        default:
          throw ArgumentError('Método HTTP no soportado: $method');
      }
    }

    try {
      var response = await doRequest();
      if (response.statusCode == 401 && auth) {
        final refreshed = await _attemptRefresh();
        if (refreshed) {
          response = await doRequest();
        } else {
          throw SessionExpiredException();
        }
      }
      return _parse(response);
    } on SocketException catch (e) {
      throw NetworkException('Sin conexión: ${e.message}');
    } on TimeoutException {
      throw NetworkException('La petición tardó demasiado');
    }
  }

  /// Intenta refrescar el access-token. Devuelve true si tuvo éxito.
  /// Si ya hay un refresh en curso, espera a que termine (mutex).
  Future<bool> _attemptRefresh() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final future = _doRefresh();
    _refreshInFlight = future;
    future.whenComplete(() => _refreshInFlight = null);
    return future;
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _tokenManager.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final uri = Uri.parse('$_refreshBaseUrl/authentication/refresh-token');
      final response = await _http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(AppConfig.defaultTimeout);
      if (response.statusCode != 200) {
        _notifyExpired();
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccess = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) {
        _notifyExpired();
        return false;
      }
      await _tokenManager.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
      return true;
    } catch (_) {
      _notifyExpired();
      return false;
    }
  }

  void _notifyExpired() {
    final cb = onSessionExpired;
    if (cb != null) cb();
  }

  dynamic _parse(http.Response response) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    String message;
    dynamic parsedBody;
    if (response.body.isEmpty) {
      message = _statusMessage(code);
    } else {
      try {
        parsedBody = jsonDecode(response.body);
        if (parsedBody is Map) {
          message = (parsedBody['message'] ?? parsedBody['detail'] ?? parsedBody['error'])
                  ?.toString() ??
              _statusMessage(code);
        } else {
          message = parsedBody.toString();
        }
      } catch (_) {
        message = response.body;
      }
    }
    throw ApiException(message, statusCode: code, body: parsedBody);
  }

  String _statusMessage(int code) {
    switch (code) {
      case 400:
        return 'Solicitud inválida';
      case 401:
        return 'No autorizado';
      case 403:
        return 'Acceso denegado';
      case 404:
        return 'Recurso no encontrado';
      case 409:
        return 'Conflicto con el estado actual';
      case 500:
        return 'Error interno del servidor';
      case 503:
        return 'Servicio no disponible';
      default:
        return 'Error HTTP $code';
    }
  }

  /// Deriva el Content-Type del archivo a partir de su extensión.
  /// `MultipartFile.fromPath` por defecto envía `application/octet-stream`,
  /// que rompe a consumidores que validan MIME (ej. la API de Gemini).
  MediaType _resolveMediaType(String path) {
    final dot = path.lastIndexOf('.');
    final ext = (dot >= 0 && dot < path.length - 1)
        ? path.substring(dot + 1).toLowerCase()
        : '';
    switch (ext) {
      // Video
      case 'mp4':  return MediaType('video', 'mp4');
      case 'mpeg':
      case 'mpg':  return MediaType('video', 'mpeg');
      case 'mov':  return MediaType('video', 'quicktime');
      case 'avi':  return MediaType('video', 'x-msvideo');
      case 'flv':  return MediaType('video', 'x-flv');
      case 'webm': return MediaType('video', 'webm');
      case 'wmv':  return MediaType('video', 'wmv');
      case '3gp':
      case '3gpp': return MediaType('video', '3gpp');
      // Imagen (para uploads de comidas)
      case 'jpg':
      case 'jpeg': return MediaType('image', 'jpeg');
      case 'png':  return MediaType('image', 'png');
      case 'webp': return MediaType('image', 'webp');
      case 'heic': return MediaType('image', 'heic');
      case 'heif': return MediaType('image', 'heif');
      default:     return MediaType('application', 'octet-stream');
    }
  }

  void dispose() => _http.close();
}
