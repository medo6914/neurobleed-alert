import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[STARTUP] main() started');

  // Non-blocking Firebase init — runApp immediately, Firebase init in background
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((_) {
    debugPrint('[STARTUP] Firebase initialized successfully');
  }).catchError((e) {
    debugPrint('[STARTUP] Firebase initialization failed: $e');
  });

  debugPrint('[STARTUP] Calling runApp()');
  runApp(const ProviderScope(child: NeuroBleedApp()));
  debugPrint('[STARTUP] runApp() completed');
}
