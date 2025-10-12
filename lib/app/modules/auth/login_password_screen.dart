import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class LoginPasswordScreen extends StatefulWidget {
  const LoginPasswordScreen({super.key});

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+976');
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1F22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Нэвтрэх'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // ☎️ Утас
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _input('Утасны дугаар (+976...)', Icons.phone),
                  validator: (v) =>
                      (v == null || v.trim().length < 8) ? 'Зөв дугаар оруулна уу' : null,
                ),

                const SizedBox(height: 12),

                // 🔒 Нууц үг
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: _input(
                    'Нууц үг',
                    Icons.lock,
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Хамгийн багадаа 6 тэмдэгт' : null,
                  onFieldSubmitted: (_) => _submit(c),
                ),

                const SizedBox(height: 16),

                // ⚠️ Алдааны мессеж (controller.error)
                Obx(() {
                  final msg = c.error.value.trim();
                  return msg.isEmpty
                      ? const SizedBox.shrink()
                      : Text(msg, style: const TextStyle(color: Colors.redAccent));
                }),

                const SizedBox(height: 20),

                // 🔘 Товч
                Obx(() => ElevatedButton(
                      onPressed: c.loading.value ? null : () => _submit(c),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFE8C00),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: c.loading.value
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Нэвтрэх',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    )),

                const Spacer(),
                const Text('© Smart Home', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF2A2B2F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _submit(AuthController c) async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    final phone = _phoneCtrl.text.trim();
    final pass  = _passCtrl.text;

    final err = await c.login(phone, pass); // ← таны controller-т таарсан дуудлага
    if (!mounted) return;

    if (err == null) {
      Get.offAllNamed('/home');
    } else {
      // auth_controller.error-д аль хэдийн хадгалж байгаа ч UI дээр snackbar-тай давхар харуулъя
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }
}
