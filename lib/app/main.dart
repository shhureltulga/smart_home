import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'data/api_client.dart';
import 'modules/auth/auth_controller.dart';
import 'routes.dart';
import 'theme.dart';

String _baseUrl() {
  if (kIsWeb) return 'http://122.201.20.196:4000';
  if (Platform.isAndroid) return 'http://122.201.20.196:4000';
  return 'http://122.201.20.196:4000';
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ApiClient(_baseUrl());
  Get.put<ApiClient>(api);
  Get.put<AuthController>(AuthController(api));

  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart Home',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.pages,
    );
  }
}
