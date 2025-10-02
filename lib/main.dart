// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppRoutes.initBindings(); // ← нэмэгдлээ
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
