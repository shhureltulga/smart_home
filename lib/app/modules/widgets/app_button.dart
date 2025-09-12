import 'package:flutter/material.dart';
import '../../theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  const AppButton({super.key, required this.label, required this.onPressed, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? AppTheme.primary : Colors.transparent,
          foregroundColor: filled ? Colors.white : AppTheme.primary,
          side: filled ? null : const BorderSide(color: AppTheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: filled ? 1 : 0,
        ),
        child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: filled ? Colors.white : AppTheme.primary)),
      ),
    );
  }
}
