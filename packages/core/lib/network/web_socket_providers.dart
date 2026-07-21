import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'web_socket_client.dart';

final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  final client = WebSocketClient();
  ref.onDispose(() => client.dispose());
  return client;
});

final webSocketConnectionProvider = StreamProvider<bool>((ref) {
  final client = ref.watch(webSocketClientProvider);
  return client.connectionState;
});

final webSocketMessagesProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final client = ref.watch(webSocketClientProvider);
  return client.messages;
});
