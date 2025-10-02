// lib/app/modules/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes.dart';
import 'auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController(text: '+97680000001');
  final _pass  = TextEditingController(text: '123456');
  final _form  = GlobalKey<FormState>();
  late final AuthController auth;

  @override
  void initState() {
    super.initState();
    auth = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    final err = await auth.login(
      _phone.text.trim(),
      _pass.text.trim(),
    );

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Амжилтгүй: $err')),
      );
      return;
    }

    // Амжилттай — Site сонгох дэлгэц рүү
    Get.offAllNamed(AppRoutes.selectSite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Нэвтрэх')),
      body: Obx(() {
        final busy = auth.loading.value;

        return AbsorbPointer(
          absorbing: busy,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Утас (+976...)',
                      hintText: '+9768xxxxxxx',
                    ),
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Заавал';
                      if (!s.startsWith('+') || s.length < 8) {
                        return 'Зөв утасны формат оруулна уу';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pass,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(labelText: 'Нууц үг'),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Дор хаяж 6 тэмдэгт' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submit,
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Нэвтрэх'),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
