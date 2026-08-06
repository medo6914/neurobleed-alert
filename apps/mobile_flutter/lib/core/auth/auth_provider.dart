import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide User, AuthProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared/entities/user.dart';
import 'package:core/core.dart';
import '../../features/notifications/push_notification_service.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider), SecureStorageService());
});

final authGuardProvider = ChangeNotifierProvider<AuthGuard>((ref) {
  final guard = AuthGuard();
  ref.listen<AuthState>(authStateProvider, (_, state) {
    guard.setAuthenticated(
      state.status == AuthStatus.authenticated,
      role: state.user?.role.name,
    );
  });
  return guard;
});

enum AuthStatus { unknown, unauthenticated, authenticated, onboarding }

class AuthState {
  final AuthStatus status;
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isOnboardingComplete;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
    this.isOnboardingComplete = false,
  });

  bool get isLoggedIn => status == AuthStatus.authenticated;
  String? get userId => user?.id;
  String? get role => user?.role.name;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isLoading,
    String? error,
    bool? isOnboardingComplete,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final SecureStorageService _storage;

  AuthNotifier(this._api, this._storage, {bool checkOnInit = true})
      : super(const AuthState()) {
    if (checkOnInit) {
      _checkAuthStatus();
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      final hasToken = await _storage.hasToken();
      if (!hasToken) {
        final onboardingDone = await _storage.getOnboardingComplete();
        state = state.copyWith(
          status: onboardingDone
              ? AuthStatus.unauthenticated
              : AuthStatus.onboarding,
          isOnboardingComplete: onboardingDone,
        );
        return;
      }

      if (!await _storage.getRememberMe()) {
        await _storage.clearAll();
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      try {
        final response = await _api.get('/v1/auth/me');
        final data = response.data;
        final user = User(
          id: data['id'],
          email: data['email'],
          phone: data['phone'],
          displayName: data['full_name'] ?? data['display_name'],
          photoUrl: data['profile_image_url'],
          role: UserRole.values.firstWhere(
            (r) => r.name == data['role'],
            orElse: () => UserRole.doctor,
          ),
          authProvider: AuthProvider.values.firstWhere(
            (p) => p.name == (data['auth_provider'] ?? 'email'),
            orElse: () => AuthProvider.email,
          ),
          isActive: data['is_active'] ?? true,
          hospitalId: data['hospital_id'],
          createdAt: DateTime.parse(data['created_at']),
          updatedAt: DateTime.parse(data['updated_at']),
        );
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } catch (e) {
        await _storage.clearAll();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password,
      {bool rememberMe = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _storage.saveRememberMe(rememberMe);
      final response = await _api.post('/v1/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data;
      await _storage.saveToken(data['access_token']);
      if (data['refresh_token'] != null) {
        await _storage.saveRefreshToken(data['refresh_token']);
      }
      await _storage.saveUserId(data['user_id']);
      await _storage.saveUserRole(data['role']);

      final user = _userFromResponse(data);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
      unawaited(_registerPush());
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تسجيل الدخول: ${_extractError(e)}',
      );
    }
  }

  Future<void> _registerPush() async {
    try {
      await PushNotificationService(_api).initialize();
    } catch (_) {}
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String role = 'user',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/v1/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
      });
      await login(email, password);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل إنشاء الحساب: ${_extractError(e)}',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/v1/auth/logout');
    } catch (_) {}
    await _storage.clearAll();
    _api.clearAuthToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/v1/auth/forgot-password', data: {
        'email': email,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل إرسال رابط إعادة تعيين كلمة المرور: ${_extractError(e)}',
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/v1/auth/reset-password', data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل إعادة تعيين كلمة المرور: ${_extractError(e)}',
      );
    }
  }

  Future<void> verifyEmail(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/v1/auth/verify-email', data: {
        'code': code,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل التحقق من البريد الإلكتروني: ${_extractError(e)}',
      );
    }
  }

  Future<void> sendPhoneVerification(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/v1/auth/send-phone-verification', data: {
        'phone': phone,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل إرسال رمز التحقق: ${_extractError(e)}',
      );
    }
  }

  Future<void> verifyPhone(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/v1/auth/verify-phone', data: {
        'phone': phone,
        'code': code,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل التحقق من رقم الهاتف: ${_extractError(e)}',
      );
    }
  }

  Future<void> sendOtp(String identifier) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/v1/auth/send-otp', data: {
        'identifier': identifier,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل إرسال رمز OTP: ${_extractError(e)}',
      );
    }
  }

  Future<void> verifyOtp(String identifier, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post('/v1/auth/verify-otp', data: {
        'identifier': identifier,
        'code': code,
      });
      final data = response.data;
      await _storage.saveToken(data['access_token']);
      if (data['refresh_token'] != null) {
        await _storage.saveRefreshToken(data['refresh_token']);
      }
      await _storage.saveUserId(data['user_id']);
      await _storage.saveUserRole(data['role']);

      final user = _userFromResponse(data);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'رمز التحقق غير صحيح: ${_extractError(e)}',
      );
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user!.getIdToken();
      final response = await _api.post('/v1/auth/google', data: {
        'id_token': idToken,
      });
      final data = response.data;
      await _storage.saveToken(data['access_token']);
      if (data['refresh_token'] != null) {
        await _storage.saveRefreshToken(data['refresh_token']);
      }
      await _storage.saveUserId(data['user_id']);
      await _storage.saveUserRole(data['role']);

      final user = _userFromResponse(data);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
      unawaited(_registerPush());
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تسجيل الدخول بواسطة Google: ${_extractError(e)}',
      );
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _api.get('/v1/auth/me');
      return response.data;
    } catch (e) {
      state = state.copyWith(
        error: 'فشل تحميل الملف الشخصي: ${_extractError(e)}',
      );
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.put('/v1/auth/me', data: data);
      final updated = _userFromResponse(response.data);
      state = state.copyWith(user: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحديث الملف الشخصي: ${_extractError(e)}',
      );
    }
  }

  Future<void> setOnboardingComplete() async {
    await _storage.setOnboardingComplete();
    if (state.status == AuthStatus.onboarding) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isOnboardingComplete: true,
      );
    }
  }

  User _userFromResponse(Map<String, dynamic> data) {
    return User(
      id: data['user_id'] ?? data['id'],
      email: data['email'],
      phone: data['phone'],
      displayName: data['full_name'] ?? data['display_name'],
      photoUrl: data['profile_image_url'] ?? data['photo_url'],
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.doctor,
      ),
      authProvider: AuthProvider.values.firstWhere(
        (p) => p.name == (data['auth_provider'] ?? 'email'),
        orElse: () => AuthProvider.email,
      ),
      isActive: data['is_active'] ?? true,
      hospitalId: data['hospital_id'],
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  String _extractError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains(':')) return msg.split(':').last.trim();
      return msg;
    }
    return e.toString();
  }
}
