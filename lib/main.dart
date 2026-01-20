// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppRoutes.initBindings(); // ← нэмэгдлээ
  MediaKit.ensureInitialized();
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Home-es',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.pages,
    );
  }
}
