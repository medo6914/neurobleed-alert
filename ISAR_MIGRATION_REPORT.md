# ISAR Migration Report

## Overview
Full migration from `isar` 3.1.0+1 (unmaintained) to `isar_community` 3.3.2 (active community fork).

## Version Details

| Property | Old | New |
|---|---|---|
| Package | `isar` 3.1.0+1 | `isar_community` 3.3.2 |
| Flutter Libs | `isar_flutter_libs` 3.1.0+1 | `isar_community_flutter_libs` 3.3.2 |
| Generator | `isar_generator` 3.1.0+1 | `isar_community_generator` 3.3.2 |
| Status | Unmaintained (3 years) | Actively maintained |
| Encryption | Not built-in | Not built-in |

## Breaking Changes

1. **Package rename**: All imports from `package:isar/isar.dart` → `package:isar_community/isar.dart`
2. **Build output format**: Generator outputs `.isar_generator.g.part` files instead of `.isar.dart` files
3. **Build target**: Generator uses `build_to: cache` instead of `output_to_source: true`
4. **Part directives**: Source files must reference `.isar_generator.g.part` instead of `.isar.dart`
5. **Generated files need `part of` declaration** to be valid Dart part files (added manually after copy)

## Files Modified

| File | Change |
|---|---|
| `packages/core/pubspec.yaml` | Replaced `isar`/`isar_flutter_libs`/`isar_generator` with `isar_community`/`isar_community_flutter_libs`/`isar_community_generator` |
| `packages/core/lib/database/collections/alert_collection.dart` | `part` directive updated |
| `packages/core/lib/database/collections/device_collection.dart` | `part` directive updated |
| `packages/core/lib/database/collections/hospital_collection.dart` | `part` directive updated |
| `packages/core/lib/database/collections/patient_collection.dart` | `part` directive updated |
| `packages/core/lib/database/collections/sensor_reading_collection.dart` | `part` directive updated |
| `packages/core/lib/database/collections/user_collection.dart` | `part` directive updated |
| `packages/core/build.yaml` | Updated to reference `source_gen:combining_builder: enabled: false` |
| `packages/core/lib/core.dart` | Added `encryption_service.dart` export |
| `packages/core/lib/di/providers.dart` | Added `encryptionServiceProvider` |
| `packages/core/lib/security/encryption_service.dart` | Fixed `Uint8List` type cast |

## New Files (Generated)

| File | Description |
|---|---|
| `packages/core/lib/database/collections/alert_collection.isar_generator.g.part` | Generated schema |
| `packages/core/lib/database/collections/device_collection.isar_generator.g.part` | Generated schema |
| `packages/core/lib/database/collections/hospital_collection.isar_generator.g.part` | Generated schema |
| `packages/core/lib/database/collections/patient_collection.isar_generator.g.part` | Generated schema |
| `packages/core/lib/database/collections/sensor_reading_collection.isar_generator.g.part` | Generated schema |
| `packages/core/lib/database/collections/user_collection.isar_generator.g.part` | Generated schema |

## Test Results

```
00:00 +12: All tests passed!
```

## Analysis Results

- `flutter analyze`: 259 issues found
- Severity: All `info` level only (`prefer_const_constructors`, `deprecated_member_use`, etc.)
- **Zero errors, zero warnings**

## Encryption Status

**Isar does NOT support built-in database encryption**, neither in the original `isar` 3.1.0+1 nor in `isar_community` 3.3.2.

**Solution applied**: Independent `EncryptionService` layer using **AES-256-GCM** via the `encrypt` package:
- `packages/core/lib/security/encryption_service.dart`
- Registered in DI as `encryptionServiceProvider`
- Exported from `core.dart`
- Key derivation using SHA-256, stored in `flutter_secure_storage`
- Fully independent of Isar — can swap database without rewriting encryption logic

## Remaining Constraints

1. The generated `.isar_generator.g.part` files are stored in source (copied from build cache) because the generator uses `build_to: cache`. These must be regenerated when collection schemas change.
2. File-based encryption at the OS level (Android file-based encryption, iOS NSFileProtection) should still be enabled for additional protection.

## Commands for Future Regeneration

```bash
cd packages/core
dart run build_runner build
# Then copy .part files from .dart_tool/build/generated/ to lib/database/collections/
```
