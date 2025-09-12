import 'package:get/get.dart';
import 'modules/auth/login_password_screen.dart';
import 'modules/home/home_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const home  = '/home';

  static final pages = <GetPage>[
    GetPage(name: login, page: () => const LoginPasswordScreen()),
    GetPage(name: home,  page: () => const HomeScreen()),
  ];
}
