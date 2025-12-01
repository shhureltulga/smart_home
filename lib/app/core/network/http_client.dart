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
  Future<List<Map<String, dynamic>>> getFloorDeviceCards(
    String siteId,
    String floorId,
  ) async {
    final res = await _dio.get('/sites/$siteId/floors/$floorId/devices/card');
    final data = res.data;

    List raw;
    if (data is Map<String, dynamic>) {
      raw = (data['devices'] ?? []) as List;
    } else if (data is List) {
      raw = data;
    } else {
      raw = const [];
    }

    return raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  
}
extension FloorApi on ApiClient {
  Future<List<Map<String, dynamic>>> getFloors(String siteId) async {
    // raw string аваад өөрсдөө задлая – формат ямар ч байсан барина
    final resp = await get<String>(
      '/api/floors',
      query: {'siteId': siteId},
      withAuth: true,
    );

    final dynamic root = jsonDecode(resp.data ?? '{}');

    // Түгээмэл wrapper-үүдийг тайлж items-г олно
    dynamic items;
    if (root is Map<String, dynamic>) {
      items = root['items'] ?? root['data'] ?? root['result'] ?? root['floors'];
      // Хэрвээ сервер шууд массив биш, нэг Map буцаасан бол массив болгож өгнө
      items ??= root;
    } else {
      items = root;
    }

    if (items is List) {
      return items.cast<Map<String, dynamic>>();
    } else if (items is Map<String, dynamic>) {
      return [items]; // ганц обьект ирсэн тохиолдолд
    } else {
      return const [];
    }
  }
}

// ---- Devices API (site + floor → devices, device → command) ----
extension DeviceApi on ApiClient {
  /// Тухайн site + floor дээрх төхөөрөмжүүдийг татна.
  /// Server { ok, devices:[...] } эсвэл { items:[...] } / шууд массив
  Future<List<Map<String, dynamic>>> getDevicesByFloor(
    String siteId,
    String floorId,
  ) async {
    final resp = await get<String>(
      '/api/sites/$siteId/floors/$floorId/devices',
      withAuth: true,
    );

    final dynamic root = jsonDecode(resp.data ?? '[]');

    dynamic items;
    if (root is Map<String, dynamic>) {
      items = root['devices'] ?? root['items'] ?? root['data'] ?? root['result'];
      items ??= (root['ok'] == true && root['devices'] is List) ? root['devices'] : null;
    } else {
      items = root;
    }

    if (items is List) return items.cast<Map<String, dynamic>>();
    if (items is Map<String, dynamic>) return [items];
    return const [];
  }

  /// 3D дээрээс дарж ON/OFF гэх мэт команд өгөх.
  /// action: 'on' | 'off' | 'toggle' | 'set_brightness' | ...
  /// value: нэмэлт утга (ж. set_brightness=70)
  Future<Map<String, dynamic>> sendDeviceCommand({
    required String deviceId,
    required String action,
    dynamic value,
  }) async {
    final body = {'action': action, if (value != null) 'value': value};

    final resp = await post<String>(
      '/api/devices/$deviceId/command',
      body: body,
      withAuth: true,
    );

    final raw = resp.data ?? '{}';
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

