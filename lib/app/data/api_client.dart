import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final String baseUrl;
  final _storage = const FlutterSecureStorage();

  ApiClient(this.baseUrl);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool withAuth = false}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'content-type': 'application/json'};

    if (withAuth) {
      final access = await _storage.read(key: 'access');
      if (access != null) headers['authorization'] = 'Bearer $access';
    }

    var res = await http.post(uri, headers: headers, body: json.encode(body));
    if (res.statusCode == 401 && withAuth && await _tryRefresh()) {
      final access = await _storage.read(key: 'access');
      headers['authorization'] = 'Bearer $access';
      res = await http.post(uri, headers: headers, body: json.encode(body));
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> get(String path, {bool withAuth = false}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{};

    if (withAuth) {
      final access = await _storage.read(key: 'access');
      if (access != null) headers['authorization'] = 'Bearer $access';
    }

    var res = await http.get(uri, headers: headers);
    if (res.statusCode == 401 && withAuth && await _tryRefresh()) {
      final access = await _storage.read(key: 'access');
      headers['authorization'] = 'Bearer $access';
      res = await http.get(uri, headers: headers);
    }
    return _decode(res);
  }

  Future<bool> _tryRefresh() async {
    final sid = await _storage.read(key: 'session_id');
    final refresh = await _storage.read(key: 'refresh');
    if (sid == null || refresh == null) return false;

    final uri = Uri.parse('$baseUrl/auth/refresh');
    final res = await http.post(uri,
        headers: {'content-type': 'application/json'},
        body: json.encode({'session_id': sid, 'refresh_token': refresh}));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = json.decode(res.body);
      await _storage.write(key: 'access', value: data['access_token']);
      await _storage.write(key: 'refresh', value: data['refresh_token']);
      await _storage.write(key: 'session_id', value: data['session_id']);
      return true;
    }
    return false;
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isNotEmpty ? json.decode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    throw Exception(body is Map ? (body['error'] ?? 'error') : 'error');
  }
}
