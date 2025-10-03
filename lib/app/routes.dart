// lib/app/routes.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'modules/auth/login_screen.dart';
import 'modules/auth/auth_controller.dart';
import 'modules/auth/auth_service.dart';

import 'core/network/http_client.dart';

import 'modules/sites/select_site_screen.dart';
import 'modules/sites/sites_controller.dart';
import 'modules/sites/sites_service.dart';

import 'modules/dashboard/dashboard_screen.dart';
import 'modules/shell/main_shell.dart';

class AppRoutes {
  static const login = '/login';
  static const selectSite = '/select-site';
  static const dashboard = '/dashboard';
  static const main = '/main';           // 🆕 MainShell

  static final pages = <GetPage>[
    GetPage(name: login, page: () => const LoginScreen()),

    // Site сонгох дэлгэц — route дээрээ service/controller-оо bind-лана
    GetPage(
      name: selectSite,
      page: () => const SelectSiteScreen(),
      binding: BindingsBuilder(() {
        // ApiClient аль хэдийн initBindings()-д бүртгэгдсэн тул шууд ашиглана
        Get.put<SitesService>(SitesService(ApiClient.I), permanent: true);
        Get.put<SitesController>(
          SitesController(Get.find<SitesService>()),
          permanent: false,
        );
      }),
    ),

    GetPage(name: dashboard, page: () => const DashboardScreen()),
    GetPage(name: '/main', page: () => const MainShell()),
  ];

  /// Апп асаахад нэг удаа дуудна — үндсэн сервисүүдээ энд бэлдэнэ.
  static Future<void> initBindings() async {
    // Network/API singleton
    Get.put<ApiClient>(ApiClient.I, permanent: true);

    // Auth service/controller
    Get.put<AuthService>(AuthService(Get.find<ApiClient>()), permanent: true);
    Get.put<AuthController>(
      AuthController(Get.find<AuthService>()),
      permanent: true,
    );
  }
}
