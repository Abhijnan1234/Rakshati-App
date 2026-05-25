// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/network_config.dart';
import 'api_exception.dart';

class ApiClient {
  const ApiClient();

  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
    Duration? timeout,
  }) {
    return _sendRequest(
      method: 'GET',
      path: path,
      token: token,
      timeout: timeout,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
    Duration? timeout,
  }) {
    return _sendRequest(
      method: 'POST',
      path: path,
      body: body,
      token: token,
      timeout: timeout,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
    Duration? timeout,
  }) {
    return _sendRequest(
      method: 'DELETE',
      path: path,
      body: body,
      token: token,
      timeout: timeout,
    );
  }

  Future<Map<String, dynamic>> _sendRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? token,
    Duration? timeout,
  }) async {
    final baseUrl = NetworkConfig.apiBaseUrl;
    final uri = Uri.parse('$baseUrl$path');

    _logRequest(
      method,
      uri,
      token: token,
      body: _sanitizeBody(body),
    );

    try {
      final response = await _dispatchHttp(
        method: method,
        uri: uri,
        token: token,
        body: body,
        timeout: timeout ?? const Duration(seconds: 6),
      );
      return _decodeResponse(method, uri, response);
    } on SocketException catch (error) {
      _logError(method, uri, error);
      throw _networkException(error);
    } on TimeoutException catch (error) {
      _logError(method, uri, error);
      throw _networkException(error);
    } on HttpException catch (error) {
      _logError(method, uri, error);
      throw ApiException(
        'HTTP error while contacting the Rakshati server: ${error.message}',
        code: 'HTTP_ERROR',
      );
    } on FormatException catch (error) {
      _logError(method, uri, error);
      throw const ApiException(
        'The server returned an unreadable response.',
        code: 'INVALID_RESPONSE',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      _logError(method, uri, error);
      throw ApiException(
        'Request failed: $error',
        code: 'REQUEST_FAILED',
      );
    }
  }

  Future<http.Response> _dispatchHttp({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
    String? token,
    required Duration timeout,
  }) {
    switch (method) {
      case 'GET':
        return http
            .get(
              uri,
              headers: _headers(token),
            )
            .timeout(timeout);
      case 'POST':
        return http
            .post(
              uri,
              headers: _headers(token),
              body: jsonEncode(body ?? <String, dynamic>{}),
            )
            .timeout(timeout);
      case 'DELETE':
        return http
            .delete(
              uri,
              headers: _headers(token),
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(timeout);
      default:
        throw UnsupportedError('Unsupported method $method');
    }
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(
    String method,
    Uri uri,
    http.Response response,
  ) {
    print(
      '[Rakshati][API] Response $method $uri '
      'status=${response.statusCode} body=${response.body}',
    );

    final dynamic decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded as Map<String, dynamic>;
    }

    final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    throw ApiException(
      (map['message'] as String?) ?? 'Request failed.',
      code: map['code'] as String?,
    );
  }

  void _logRequest(
    String method,
    Uri uri, {
    String? token,
    Object? body,
  }) {
    print(
      '[Rakshati][API] Request $method $uri '
      'auth=${token != null ? 'Bearer' : 'none'} body=$body',
    );
  }

  void _logError(String method, Uri uri, Object error) {
    print('[Rakshati][API] Error $method $uri error=$error');
  }

  ApiException _networkException(Object? error) {
    final detail = error == null ? '' : ' Last error: $error.';
    return ApiException(
      'Unable to reach the Rakshati server at ${NetworkConfig.apiBaseUrl}.'
      '$detail Confirm that the backend is running, the phone is on the same Wi-Fi network as the PC, '
      'and the app was built with the correct `--dart-define=NETWORK_BASE_URL=...` value if needed.',
      code: 'NETWORK_UNREACHABLE',
    );
  }

  Map<String, dynamic>? _sanitizeBody(Map<String, dynamic>? body) {
    if (body == null) {
      return null;
    }

    return body.map(
      (key, value) => MapEntry(
        key,
        key.toLowerCase().contains('password') ? '***' : value,
      ),
    );
  }
}
