import 'package:flutter/material.dart';

/// AsyncView нь 2 янзаар ажиллана:
/// A) Хуучин горим: loading/error/isEmpty/emptyText/child
/// B) Шинэ горим: future + builder (FutureBuilder wrapper)
class AsyncView<T> extends StatelessWidget {
  // ---- A) хуучин горимын параметрүүд ----
  final bool? loading;
  final String? error;
  final bool isEmpty;
  final String? emptyText;
  final Widget? child;

  // ---- B) шинэ горимын параметрүүд ----
  final Future<T>? future;
  final Widget Function(BuildContext context, T data)? builder;

  // Нэмэлт тохиргоо
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, Object err)? errorBuilder;

  const AsyncView({
    super.key,

    // A) хуучин горим
    this.loading,
    this.error,
    this.isEmpty = false,
    this.emptyText,
    this.child,

    // B) шинэ горим
    this.future,
    this.builder,

    // нэмэлт
    this.loadingWidget,
    this.errorBuilder,
  });

  bool get _isFutureMode => future != null && builder != null;

  @override
  Widget build(BuildContext context) {
    // -------------------------
    // B) Future горим (шинэ)
    // -------------------------
    if (_isFutureMode) {
      return FutureBuilder<T>(
        future: future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return loadingWidget ??
                const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            final err = snap.error ?? Exception('Unknown error');
            if (errorBuilder != null) return errorBuilder!(ctx, err);
            return Center(child: Text('Алдаа: $err'));
          }

          if (!snap.hasData) {
            // data байхгүй бол empty гэж үзнэ
            return Center(child: Text(emptyText ?? 'Одоогоор хоосон байна.'));
          }

          return builder!(ctx, snap.data as T);
        },
      );
    }

    // -------------------------
    // A) Хуучин горим
    // -------------------------
    final isLoading = loading ?? false;

    if (isLoading) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (error != null && error!.trim().isNotEmpty) {
      if (errorBuilder != null) return errorBuilder!(context, error!);
      return Center(child: Text('Алдаа: $error'));
    }

    if (isEmpty) {
      return Center(child: Text(emptyText ?? 'Одоогоор хоосон байна.'));
    }

    return child ?? const SizedBox.shrink();
  }
}
