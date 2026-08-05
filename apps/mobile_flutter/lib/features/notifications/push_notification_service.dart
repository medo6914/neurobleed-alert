import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final api = ref.read(apiClientProvider);
  return PushNotificationService(api);
});

class PushNotificationService {
  final ApiClient _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  PushNotificationService(this._api);

  /// Initializes FCM: requests permission, registers the token with the
  /// backend, and wires foreground/background/terminated message handlers.
  Future<void> initialize() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await _messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
      _messaging.onTokenRefresh.listen(_registerToken);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] foreground message: ${message.notification?.title}');
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] opened from: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('[FCM] init failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.post('/v1/notifications/register-token', data: {
        'fcm_token': token,
        'platform':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
      debugPrint('[FCM] token registered');
    } catch (e) {
      debugPrint('[FCM] token registration failed: $e');
    }
  }

  Future<String?> getToken() => _messaging.getToken();
}
