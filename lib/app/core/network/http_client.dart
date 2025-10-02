// lib/app/core/network/http_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

import '../config/env.dart';
import '../config/endpoints.dart';
import '../storage/secure_storage.dart';

/// Dio суурьтай API клиент:
/// - extra.withAuth == true бол Authorization header автоматаар нэмнэ
/// - 401 үед refresh → эх хүсэлтийг retry
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppEnv.current.baseUrl,
        connectTimeout: AppEnv.current.connectTimeout,
        receiveTimeout: AppEnv.current.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final withAuth = options.extra['withAuth'] == true;
          if (withAuth) {
            final token = await SecureStore.instance.read(SecureKeys.accessToken);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final req = error.requestOptions;
          final withAuth = req.extra['withAuth'] == true;
          final unauthorized = (error.response?.statusCode == 401) ||
              (error.type == DioExceptionType.badResponse &&
                  error.response?.statusCode == 401);

          if (withAuth && unauthorized && !_isRefreshing) {
            try {
              final ok = await _refreshTokens();
              if (ok) {
                final clone = await _retry(req);
                return handler.resolve(clone);
              }
            } catch (_) {/* ignore */}
          }

          if (withAuth && unauthorized) {
            await SecureStore.instance.clearAuth();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient I = ApiClient._internal();
  late final Dio _dio;

  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  // ───────────────────────────
  // Low-level: raw get/post/put/delete (Dio Response буцаана)
  // ───────────────────────────
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    bool withAuth = false,
    Map<String, dynamic>? headers,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: query,
      options: Options(headers: headers, extra: {'withAuth': withAuth}),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic body,
    bool withAuth = false,
    Map<String, dynamic>? headers,
  }) {
    return _dio.post<T>(
      path,
      data: body,
      options: Options(headers: headers, extra: {'withAuth': withAuth}),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic body,
    bool withAuth = false,
    Map<String, dynamic>? headers,
  }) {
    return _dio.put<T>(
      path,
      data: body,
      options: Options(headers: headers, extra: {'withAuth': withAuth}),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic body,
    bool withAuth = false,
    Map<String, dynamic>? headers,
  }) {
    return _dio.delete<T>(
      path,
      data: body,
      options: Options(headers: headers, extra: {'withAuth': withAuth}),
    );
  }

  // ───────────────────────────
  // High-level: JSON helpers (AuthService энэ функцийг ашиглана)
  // by default withAuth=true (хамгаалалттай API-ууд)
  // ───────────────────────────
  Future<R> getJson<R>(
    String path, {
    Map<String, dynamic>? query,
    bool withAuth = true,
  }) async {
    final resp = await get<String>(path, query: query, withAuth: withAuth);
    return jsonDecode(resp.data ?? '{}') as R;
  }

  Future<R> postJson<R>(
    String path,
    Object body, {
    bool withAuth = true,
  }) async {
    // Dio өөрөө JSON болгоно — string буцаалтыг JSON болгохын тулд String аваад decode хийе
    final resp = await post<String>(path, body: body, withAuth: withAuth);
    final raw = resp.data;
    if (raw is String) {
      return jsonDecode(raw.isEmpty ? '{}' : raw) as R;
    }
    // Хэрэв сервер аль хэдийн Map буцаасан бол шууд cast хийх fallback
    return (resp.data as R);
  }

  Future<R> putJson<R>(
    String path,
    Object body, {
    bool withAuth = true,
  }) async {
    final resp = await put<String>(path, body: body, withAuth: withAuth);
    return jsonDecode(resp.data ?? '{}') as R;
  }

  Future<R> deleteJson<R>(
    String path, {
    Object? body,
    bool withAuth = true,
  }) async {
    final resp = await delete<String>(path, body: body, withAuth: withAuth);
    return jsonDecode(resp.data ?? '{}') as R;
  }

  // ───────────────────────────
  // 401 refresh logic
  // ───────────────────────────
  Future<bool> _refreshTokens() async {
    if (_isRefreshing) {
      return _refreshCompleter!.future;
    }
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final rt = await SecureStore.instance.read(SecureKeys.refreshToken);
      final sid = await SecureStore.instance.read(SecureKeys.sessionId);
      if (rt == null || rt.isEmpty || sid == null || sid.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final resp = await _dio.post(
        ApiPaths.refresh,
        data: {'session_id': sid, 'refresh_token': rt},
        options: Options(extra: {'withAuth': false}),
      );

      final data = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : jsonDecode(resp.data?.toString() ?? '{}') as Map<String, dynamic>;

      final newAccess = data['access_token'] as String?;
      final newRefresh = data['refresh_token'] as String?;
      final newSessionId = (data['session_id'] as String?) ?? sid;

      if (newAccess == null || newAccess.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      await SecureStore.instance.write(SecureKeys.accessToken, newAccess);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await SecureStore.instance.write(SecureKeys.refreshToken, newRefresh);
      }
      await SecureStore.instance.write(SecureKeys.sessionId, newSessionId);

      _refreshCompleter!.complete(true);
      return true;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions req) {
    final opts = Options(
      method: req.method,
      headers: req.headers,
      extra: req.extra,
      contentType: req.contentType,
      responseType: req.responseType,
      followRedirects: req.followRedirects,
      validateStatus: req.validateStatus,
      receiveDataWhenStatusError: req.receiveDataWhenStatusError,
    );
    return _dio.request<dynamic>(
      req.path,
      data: req.data,
      queryParameters: req.queryParameters,
      options: opts,
    );
  }
}
