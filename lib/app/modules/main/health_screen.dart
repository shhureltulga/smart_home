import 'package:flutter/material.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Эрүүл мэнд')),
      body: const Center(child: Text('Эрүүл мэндийн хяналтын самбар (skeleton)')),
    );
  }
}
