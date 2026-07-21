import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/auth/phone_verification_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/shell/shell_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/patients/patient_search_screen.dart';
import '../../features/patients/register_patient_screen.dart';
import '../../features/patients/patient_detail_screen.dart';
import '../../features/patients/patient_history_screen.dart';
import '../../features/patients/medical_info_screen.dart';
import '../../features/patients/emergency_contact_screen.dart';
import '../../features/patients/admission_screen.dart';
import '../../features/patients/discharge_screen.dart';
import '../../features/patients/patient_notes_screen.dart';
import '../../features/patients/medical_documents_screen.dart';
import '../../features/patients/medical_timeline_screen.dart';
import '../../features/patients/vitals_history_screen.dart';
import '../../features/patients/alerts_history_screen.dart';
import '../../features/alerts/alerts_screen.dart';
import '../../features/patients/risk_history_screen.dart';
import '../../features/patients/audit_history_screen.dart';
import '../../features/ai/screens/risk_assessment_screen.dart';
import '../../features/ai/screens/risk_history_screen.dart' as ai;
import '../../features/ai/screens/ai_dashboard_screen.dart';
import '../../features/devices/screens/device_list_screen.dart';
import '../../features/devices/screens/device_detail_screen.dart';
import '../../features/devices/screens/register_device_screen.dart';
import '../../features/devices/screens/edit_device_screen.dart';
import '../../features/devices/screens/assign_device_screen.dart';
import '../../features/devices/screens/device_health_screen.dart';
import '../../features/devices/screens/device_diagnostics_screen.dart';
import '../../features/devices/screens/device_history_screen.dart';
import '../../features/devices/screens/ota_update_screen.dart';
import '../../features/devices/screens/pair_device_screen.dart';
import '../../features/monitoring/screens/live_monitoring_screen.dart';
import '../../features/monitoring/screens/patient_monitor_screen.dart';

class AppRouter {
  final AuthGuard _authGuard;

  AppRouter(this._authGuard);

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _authGuard,
    redirect: _authGuard.guard,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'resetPassword',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verifyEmail',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/phone-verification',
        name: 'phoneVerification',
        builder: (context, state) => const PhoneVerificationScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final identifier = state.uri.queryParameters['identifier'] ?? '';
          return OtpScreen(identifier: identifier);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/patients',
            name: 'patients',
            builder: (context, state) => const PatientSearchScreen(),
            routes: [
              GoRoute(
                path: 'register',
                name: 'register-patient',
                builder: (context, state) => const RegisterPatientScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'patient-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PatientDetailScreen(patientId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'patient-edit',
                    builder: (context, state) {
                      return const RegisterPatientScreen();
                    },
                  ),
                  GoRoute(
                    path: 'history',
                    name: 'patient-history',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return PatientHistoryScreen(patientId: id);
                    },
                  ),
                  GoRoute(
                    path: 'medical-info',
                    name: 'patient-medical-info',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MedicalInfoScreen(patientId: id);
                    },
                  ),
                  GoRoute(
                    path: 'emergency-contacts',
                    name: 'patient-emergency-contacts',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return EmergencyContactScreen(patientId: id);
                    },
                  ),
                  GoRoute(
                    path: 'admit',
                    name: 'patient-admit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AdmissionScreen(patientId: id);
                    },
                  ),
                  GoRoute(
                    path: 'discharge',
                    name: 'patient-discharge',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return DischargeScreen(patientId: id);
                    },
                  ),
                  GoRoute(
                    path: 'notes',
                    name: 'patient-notes',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return PatientNotesScreen(patientId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'add',
                        name: 'patient-add-note',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return PatientNotesScreen(patientId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'documents',
                    name: 'patient-documents',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MedicalDocumentsScreen(patientId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'add',
                        name: 'patient-add-document',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return MedicalDocumentsScreen(patientId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'timeline',
                    name: 'patient-timeline',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MedicalTimelineScreen(patientId: id);
                    },
                  ),
                  GoRoute(
                    path: 'vitals',
                    name: 'patient-vitals',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return VitalsHistoryScreen(patientId: id);
                    },
                  ),
                  GoRoute(
                    path: 'alerts',
                    name: 'patient-alerts',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AlertsHistoryScreen(patientId: id);
                    },
                  ),
                  GoRoute(
                    path: 'risks',
                    name: 'patient-risks',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return RiskHistoryScreen(patientId: id);
                    },
                  ),
                  GoRoute(
                    path: 'audit',
                    name: 'patient-audit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AuditHistoryScreen(patientId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/devices',
            name: 'devices',
            builder: (context, state) => const DeviceListScreen(),
            routes: [
              GoRoute(
                path: 'register',
                name: 'device-register',
                builder: (context, state) => const RegisterDeviceScreen(),
              ),
              GoRoute(
                path: 'pair',
                name: 'device-pair',
                builder: (context, state) => const PairDeviceScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'device-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return DeviceDetailScreen(deviceId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'device-edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return EditDeviceScreen(deviceId: id);
                    },
                  ),
                  GoRoute(
                    path: 'assign',
                    name: 'device-assign',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AssignDeviceScreen(deviceId: id);
                    },
                  ),
                  GoRoute(
                    path: 'health',
                    name: 'device-health',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return DeviceHealthScreen(deviceId: id);
                    },
                  ),
                  GoRoute(
                    path: 'diagnostics',
                    name: 'device-diagnostics',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return DeviceDiagnosticsScreen(deviceId: id);
                    },
                  ),
                  GoRoute(
                    path: 'ota',
                    name: 'device-ota',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return OtaUpdateScreen(deviceId: id);
                    },
                  ),
                  GoRoute(
                    path: 'history',
                    name: 'device-history',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return DeviceHistoryScreen(deviceId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/monitoring',
            name: 'monitoring',
            builder: (context, state) => const LiveMonitoringScreen(),
            routes: [
              GoRoute(
                path: ':patientId',
                name: 'monitoring-patient',
                builder: (context, state) {
                  final patientId = state.pathParameters['patientId']!;
                  return PatientMonitorScreen(patientId: patientId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/ai',
            name: 'ai',
            builder: (context, state) => const AIDashboardScreen(),
            routes: [
              GoRoute(
                path: 'risk-assess/:patientId',
                name: 'ai-risk-assess',
                builder: (context, state) {
                  final patientId = state.pathParameters['patientId']!;
                  return RiskAssessmentScreen(patientId: patientId);
                },
              ),
              GoRoute(
                path: 'risk-history/:patientId',
                name: 'ai-risk-history',
                builder: (context, state) {
                  final patientId = state.pathParameters['patientId']!;
                  return ai.RiskHistoryScreen(patientId: patientId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/alerts',
            name: 'alerts',
            builder: (context, state) => const AlertsScreen(),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Reports')),
            ),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Notifications')),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/admin',
            name: 'admin',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Admin Panel')),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
