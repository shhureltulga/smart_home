import 'package:flutter/material.dart';

class AsyncView extends StatelessWidget {
  final bool loading;
  final String? error;
  final Widget child;
  final String? emptyText;
  final bool isEmpty;

  const AsyncView({
    super.key,
    required this.loading,
    required this.error,
    required this.child,
    this.emptyText,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && error!.isNotEmpty) {
      return Center(child: Text('Алдаа: $error'));
    }
    if (isEmpty) {
      return Center(child: Text(emptyText ?? 'Одоогоор хоосон байна.'));
    }
    return child;
  }
}
