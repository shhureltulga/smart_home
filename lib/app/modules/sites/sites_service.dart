import 'package:dio/dio.dart';
import 'package:smart_home/app/core/network/http_client.dart';
import 'package:smart_home/app/data/models/site.dart';
import 'package:smart_home/app/core/config/endpoints.dart';
import 'package:smart_home/app/data/models/site_overview.dart';

class SitesService {
  final ApiClient _api;
  SitesService(this._api);

  Future<List<Site>> fetchSites({required String householdId}) async {
    try {
      final resp = await _api.get<dynamic>(
        '/api/sites',
        query: {'household_id': householdId},
        withAuth: true,
      );

      final data = resp.data;

      // 1) Хэрэв сервер шууд массив өгвөл
      if (data is List) {
        return data
            .cast<dynamic>()
            .map((e) => Site.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // 2) Хэрэв { ok, sites: [...] } хэлбэртэй өгвөл
      if (data is Map<String, dynamic>) {
        final list = data['sites'];
        if (list is List) {
          return list
              .cast<dynamic>()
              .map((e) => Site.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        // ok=false, эсвэл sites байхгүй бол хоосон буцаая
        return <Site>[];
      }

      // Танихгүй бүтэц
      return <Site>[];
    } on DioException catch (e) {
      // Алдааг дотор нь харахад тус болохоор дэлгэрэнгүй логлоё
      final code = e.response?.statusCode;
      final body = e.response?.data;
      // ignore: avoid_print
      print('[SitesService] fetchSites error: status=$code body=$body');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('[SitesService] fetchSites error: $e');
      rethrow;
    }
  }
  Future<SiteOverview> fetchOverview(String siteId) async {
    final r = await _api.get(ApiPaths.siteOverview(siteId), withAuth: true);
    final data = r.data as Map<String, dynamic>?;

    if (data?['ok'] == true) {
      return SiteOverview.fromJson(data!);
    }
    throw DioException(
      requestOptions: r.requestOptions,
      response: r,
      message: 'fetchOverview_failed',
      type: DioExceptionType.badResponse,
    );
  }
}
