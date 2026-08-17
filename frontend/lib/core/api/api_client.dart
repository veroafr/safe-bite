import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/session_storage.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  Future<String?> _getToken() async {
    return SessionStorage.getToken();
  }

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return uri;

    final cleanQuery = <String, String>{};
    query.forEach((key, value) {
      if (value != null) cleanQuery[key] = value.toString();
    });
    return uri.replace(queryParameters: {...uri.queryParameters, ...cleanQuery});
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool withAuth = true,
  }) async {
    final response = await http.get(
      _buildUri(path, query),
      headers: await _headers(withAuth: withAuth),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final response = await http.post(
      _buildUri(path, null),
      headers: await _headers(withAuth: withAuth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final response = await http.put(
      _buildUri(path, null),
      headers: await _headers(withAuth: withAuth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path, {bool withAuth = true}) async {
    final response = await http.delete(
      _buildUri(path, null),
      headers: await _headers(withAuth: withAuth),
    );
    return _handleResponse(response);
  }

  Future<List<int>> getBytes(String path, {bool withAuth = true}) async {
    final response = await http.get(
      _buildUri(path, null),
      headers: await _headers(withAuth: withAuth),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        'Error ${response.statusCode}: ${response.reasonPhrase ?? 'algo salio mal'}',
      );
    }
    return response.bodyBytes;
  }

  dynamic _handleResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }

    if (!isSuccess) {
      final message = (decoded is Map && decoded['mensaje'] != null)
          ? decoded['mensaje'].toString()
          : (decoded is Map && decoded['message'] != null)
              ? decoded['message'].toString()
              : 'Error ${response.statusCode}: ${response.reasonPhrase ?? 'algo salio mal'}';
      throw ApiException(response.statusCode, message);
    }

    return decoded;
  }
}