import 'package:flutter/material.dart';

typedef ItemBuilder<T> = Widget Function(BuildContext, T data);

class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.empty,
    this.onError,
    this.emptyWhen,
  });

  final Future<T> future;
  final ItemBuilder<T> builder;
  final Widget? loading;
  final Widget? empty;
  final String Function(Object error)? onError;
  final bool Function(T data)? emptyWhen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return loading ?? const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          final msg = onError?.call(snap.error!) ?? 'Something went wrong';
          return Center(child: Text(msg, style: const TextStyle(color: Colors.redAccent)));
        }
        final data = snap.data as T;
        if (emptyWhen?.call(data) == true) {
          return empty ?? const SizedBox.shrink();
        }
        return builder(context, data);
      },
    );
  }
}