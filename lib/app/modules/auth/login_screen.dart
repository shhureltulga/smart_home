import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme.dart';
import '../widgets/app_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width * 0.1).clamp(
      const EdgeInsets.symmetric(horizontal: 16.0),
      const EdgeInsets.symmetric(horizontal: 32.0),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text('Welcome', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Sign in to continue', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              const TextField(decoration: InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 24),
              AppButton(label: 'Sign In', onPressed: () => Get.offAllNamed('/home')),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
