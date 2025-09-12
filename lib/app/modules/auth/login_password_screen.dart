import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class LoginPasswordScreen extends StatefulWidget {
  const LoginPasswordScreen({super.key});

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+976');
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

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
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _input('Утасны дугаар (+976...)', Icons.phone),
                  validator: (v) =>
                      (v == null || v.trim().length < 8) ? 'Зөв дугаар оруулна уу' : null,
                  onSaved: (v) => c.phone.value = v!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: _input('Нууц үг', Icons.lock, suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  )),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Хамгийн багадаа 6 тэмдэгт' : null,
                  onSaved: (v) => c.password.value = v ?? '',
                  onFieldSubmitted: (_) => _submit(c),
                ),
                const SizedBox(height: 20),
                Obx(() => ElevatedButton(
                  onPressed: c.isLoading.value ? null : () => _submit(c),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE8C00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: c.isLoading.value
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Нэвтрэх', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Future<void> _submit(AuthController c) async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    final ok = await c.login();
    if (!mounted) return;
    if (ok) {
      Get.offAllNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нэвтрэх амжилтгүй. Дугаар/нууц үгээ шалга.')),
      );
    }
  }
}
