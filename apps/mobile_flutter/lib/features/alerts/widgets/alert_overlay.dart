import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';

class AlertOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const AlertOverlay({super.key, required this.child});

  @override
  ConsumerState<AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends ConsumerState<AlertOverlay> {
  StreamSubscription<Map<String, dynamic>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    final client = ref.read(webSocketClientProvider);
    _subscription = client.messages.listen((msg) {
      if (msg['type'] == 'alert_created') {
        final message = msg['message'] as String? ?? 'New alert';
        final severity = msg['severity'] as String? ?? 'medium';
        if (mounted) {
          _showAlert(context, message, severity);
        }
      }
    });
  }

  void _showAlert(BuildContext context, String message, String severity) {
    final color = switch (severity) {
      'critical' => NeuroColors.critical,
      'high' => NeuroColors.high,
      'medium' => NeuroColors.medium,
      _ => NeuroColors.info,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_rounded,
                color: NeuroColors.textPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: NeuroColors.textPrimary,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
