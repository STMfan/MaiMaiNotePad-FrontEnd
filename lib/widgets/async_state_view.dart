import 'package:flutter/material.dart';

class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.builder,
    this.errorMessage,
    this.onRetry,
    this.emptyWidget,
    this.loadingWidget,
    this.isEmpty = false,
  });

  final bool isLoading;
  final bool isEmpty;
  final String? errorMessage;
  final Widget Function(BuildContext context) builder;
  final VoidCallback? onRetry;
  final Widget? emptyWidget;
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('重试'),
              ),
            ],
          ],
        ),
      );
    }

    if (isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return builder(context);
  }
}


