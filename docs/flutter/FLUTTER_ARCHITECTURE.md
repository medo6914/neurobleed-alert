# Flutter Architecture

> Baseline — Phase 1

---

## Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        apps/mobile_flutter                                  │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │  Presentation (features)                                           │   │
│  │  ├── auth/        login_screen, register_screen                    │   │
│  │  ├── dashboard/   dashboard_screen                                 │   │
│  │  ├── patients/    patient_detail_screen, create_patient_screen     │   │
│  │  ├── alerts/      alerts_screen                                    │   │
│  │  └── shared/      widgets/patient_card.dart                        │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │  Core (app-level)                                                   │   │
│  │  ├── theme/     app_theme.dart                                      │   │
│  │  ├── auth/      auth_provider.dart                                  │   │
│  │  ├── api/       api_client.dart                                     │   │
│  │  └── routes/    app_router.dart                                     │   │
│  └────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────┘
│
├── packages/design_system      Tokens, Components, Foundations
├── packages/core               Config, Network, Router, Storage, Localization
└── packages/shared             Entities, Utils, Extensions
```

### What Exists (Baseline)

| Layer | Status | Description |
|-------|--------|-------------|
| `packages/design_system` | ✅ Implemented | 42 color tokens, full Material 3 typography, 7 components |
| `packages/shared/entities` | ✅ Implemented | User, Patient, Device, SensorReading, Alert, Hospital |
| `packages/shared/utils` | ✅ Implemented | Validators, Formatters, Constants |
| `packages/shared/extensions` | ✅ Implemented | BuildContext, DateTime, String extensions |
| `packages/core/config` | ✅ Implemented | AppConfig with environment variables |
| `packages/core/network` | ✅ Implemented | ApiClient (Dio), WebSocketClient, ApiExceptions |
| `packages/core/router` | ✅ Implemented | GoRouter config, AuthGuard |
| `packages/core/storage` | ✅ Implemented | SecureStorageService, LocalDatabaseService (Isar skeleton) |
| `packages/core/localization` | ✅ Implemented | AR/EN localization delegate and l10n |
| `apps/mobile_flutter/features` | 🚧 Partial | Login, Register, Dashboard, PatientDetail, CreatePatient, Alerts screens |
| `apps/mobile_flutter/core` | 🚧 Partial | ApiClient wrapper, AuthProvider, AppTheme, AppRouter |

### What Is Planned (Milestone 3+)

| Layer | Status | Description |
|-------|--------|-------------|
| **Application / Use Cases** | 📋 Planned | Business logic layer with 17+ use cases |
| **Repository Interfaces** (domain) | 📋 Planned | `AuthRepository`, `PatientRepository`, etc. |
| **Repository Implementations** (data) | 📋 Planned | `Impl` classes, remote + local data sources |
| **DTOs / Mappers** | 📋 Planned | Data-layer JSON models and entity mappers |
| **Presentation Providers** | 📋 Planned | Riverpod StateNotifier providers, ViewModels |
| **Data Sources** (remote + local) | 📋 Planned | RemoteDataSource, LocalDataSource implementations |
| **DI registration** | 📋 Planned | Provider / repository / use case provider registrations |

---

## Package Structure

```
neurobleed-alert/
├── apps/
│   └── mobile_flutter/
│       └── lib/
│           ├── main.dart
│           ├── core/
│           │   ├── theme/app_theme.dart
│           │   ├── auth/auth_provider.dart
│           │   ├── api/api_client.dart
│           │   └── routes/app_router.dart
│           ├── features/
│           │   ├── auth/
│           │   │   ├── login_screen.dart
│           │   │   └── register_screen.dart
│           │   ├── dashboard/
│           │   │   └── dashboard_screen.dart
│           │   ├── patients/
│           │   │   ├── patient_detail_screen.dart
│           │   │   └── create_patient_screen.dart
│           │   └── alerts/
│           │       └── alerts_screen.dart
│           ├── models/patient_model.dart
│           ├── routes/app_router.dart
│           └── shared/widgets/patient_card.dart
│
├── packages/
│   ├── design_system/
│   │   └── lib/
│   │       ├── tokens/          # Colors, Typography, Spacing, Radius, Shadows, Duration
│   │       ├── components/      # AppButton, AppCard, AppInput, AlertBanner, AppDialog, VitalsLineChart, PatientVitalsCard
│   │       └── foundations/     # ResponsiveHelper, AnimationCurves
│   │
│   ├── core/
│   │   └── lib/
│   │       ├── config/          # AppConfig
│   │       ├── network/         # ApiClient, WebSocketClient, ApiExceptions
│   │       ├── router/          # AppRouter, AuthGuard
│   │       ├── storage/         # SecureStorageService, LocalDatabaseService (Isar)
│   │       └── localization/    # AR/EN localization
│   │
│   └── shared/
│       └── lib/
│           ├── entities/        # User, Patient, Device, SensorReading, Alert, Hospital
│           ├── utils/           # Validators, Formatters, Constants
│           └── extensions/      # BuildContext, DateTime, String extensions
```

---

## Planned Layers (Milestone 3+)

### Application Layer (Use Cases)

```dart
// Planned directory structure:
// packages/core/lib/application/use_cases/
//   ├── auth/
//   │   ├── login_use_case.dart
//   │   └── logout_use_case.dart
//   ├── patient/
//   │   ├── get_patients_use_case.dart
//   │   ├── get_patient_by_id_use_case.dart
//   │   ├── create_patient_use_case.dart
//   │   └── update_patient_use_case.dart
//   ├── alert/
//   │   ├── get_alerts_use_case.dart
//   │   └── acknowledge_alert_use_case.dart
//   └── sync/
//       ├── sync_patients_use_case.dart
//       └── sync_readings_use_case.dart
```

### Domain Layer (Repository Interfaces)

```dart
// Planned directory structure:
// packages/shared/lib/repositories/  (interfaces)
//   ├── auth_repository.dart
//   ├── patient_repository.dart
//   ├── device_repository.dart
//   ├── alert_repository.dart
//   └── sync_repository.dart
```

### Data Layer (Implementations)

```dart
// Planned directory structure:
// packages/core/lib/data/repositories/   (Impl classes)
//   ├── auth_repository_impl.dart
//   ├── patient_repository_impl.dart
//   ├── device_repository_impl.dart
//   ├── alert_repository_impl.dart
//   ├── reading_repository_impl.dart
//   ├── sync_repository_impl.dart
//   └── settings_repository_impl.dart
//
// packages/core/lib/data/datasources/
//   ├── remote/
//   │   ├── auth_remote_datasource.dart
//   │   ├── patient_remote_datasource.dart
//   │   ├── device_remote_datasource.dart
//   │   ├── alert_remote_datasource.dart
//   │   ├── reading_remote_datasource.dart
//   │   └── websocket_datasource.dart
//   └── local/
//       ├── auth_local_datasource.dart
//       ├── patient_local_datasource.dart
//       ├── reading_local_datasource.dart
//       ├── alert_local_datasource.dart
//       └── pending_actions_datasource.dart
```

### Presentation Layer (State Management)

```dart
// Planned: Riverpod StateNotifier providers
// File: packages/core/lib/presentation/providers/
//   ├── auth_provider.dart
//   ├── patient_provider.dart
//   ├── device_provider.dart
//   ├── alert_provider.dart
//   ├── sync_provider.dart
//   ├── settings_provider.dart
//   └── connectivity_provider.dart
```

---

## Current Data Flow

```
User opens Patient List Screen
         │
[Presentation] Screen reads from local state / API directly
         │
[Core] ApiClient.get() → Dio HTTP call
         │
[Data] Returns JSON → Screen displays
```

### Future Data Flow (Post-Milestone 3)

```
User opens Patient List Screen
         │
[Presentation] Riverpod Provider.watch()
         │
[Application] GetPatientsUseCase.call()
         │
[Domain] PatientRepository.getPatients()  (interface)
         │
[Data] PatientRepositoryImpl.getPatients()
         │
         ├──→ [Remote] GET /v1/patients/
         │       ↓
         │    Dio Response → PatientDTO
         │       ↓
         │    Mapper: PatientDTO → Patient (Entity)
         │       ↓
         │    Cache in Local DB (Isar)
         │
         └──→ [Local] Fallback if offline
                     ↓
                  Isar Query → Patient (Entity)
                     ↓
                  Return cached data
         │
[Application] Return List<Patient>
         │
[Presentation] Update UI via Riverpod
```

---

## Testing Strategy

| Type | Tool | Location | Coverage Target |
|------|------|----------|-----------------|
| Unit Tests | flutter_test | `packages/*/test/` | 90%+ (entities, utils, tokens) |
| Widget Tests | flutter_test | `apps/mobile_flutter/test/widgets/` | 80%+ (all components) |
| Integration Tests | integration_test | `apps/mobile_flutter/test/integration/` | Critical flows |

```yaml
# Planned test directory structure (post-Milestone 3)
test/
├── unit/
│   ├── domain/
│   ├── application/
│   └── data/
├── widgets/
│   ├── shared/
│   └── features/
├── integration/
│   ├── auth_flow_test.dart
│   ├── patient_flow_test.dart
│   └── sync_flow_test.dart
└── golden/
    ├── login_screen_test.dart
    └── dashboard_screen_test.dart
```

---

## Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State Management | Riverpod | Compile-safe, testable, no BuildContext required |
| Navigation | GoRouter | Declarative, deep linking, redirect guards |
| Local DB | Isar | Fast, embedded, NoSQL for medical time-series |
| HTTP Client | Dio | Interceptors, retry, cancellation, multipart |
| WebSocket | web_socket_channel | Standard, compatible with Dio auth |
| Code Generation | freezed + json_serializable | Immutable models, union types, JSON |
| DI | Riverpod (manual) | No code generation needed, explicit |
| Charts | fl_chart | Customizable, supports real-time updates |
| Monorepo | Melos | Shared packages, unified versioning, fast CI |
