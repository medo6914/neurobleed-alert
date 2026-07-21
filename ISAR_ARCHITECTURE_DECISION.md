# Architecture Decision Record: Local Database & Encryption

| Field | Value |
|---|---|
| **Title** | Local Database: isar_community 3.3.2 with Independent AES-256-GCM Encryption |
| **Status** | **Accepted** |
| **Date** | 2026-07-19 |
| **Decision Maker** | Architecture Review |
| **Supersedes** | Original `isar` 3.1.0+1 (unmaintained) |

---

## 1. Why isar_community 3.3.2 Instead of Isar 4?

### Isar 4 Status
- Last prerelease: `4.0.0-dev.14` (published **2+ years ago**)
- Official README states: *"ISAR V4 IS NOT READY FOR PRODUCTION USE"*
- No stable release, no release date announced
- Original author (Simon Leier) stepped back from active maintenance
- The v4 branch on GitHub has seen no meaningful commits in over a year

### isar_community 3.3.2 Status
- Active community fork with **regular releases** (latest: 3 months ago)
- 83k+ weekly downloads on pub.dev
- 157 likes, actively maintained by multiple contributors
- Fixes critical bugs from the original 3.1.0+1 (analyzer compatibility, Windows crashes, IndexNotFound errors)
- **Drop-in replacement** for `isar` 3.x — same API, same annotations, same query syntax
- Binary releases available for all platforms (including ARM64 iOS Simulator)

### Decision
| Criterion | isar_community 3.3.2 | Isar 4 |
|---|---|---|
| Production-ready | ✅ Yes | ❌ No (alpha) |
| Maintained | ✅ Yes (3 months ago) | ❌ No (2+ years stale) |
| API stable | ✅ 3.x API frozen | ❌ Breaking changes expected |
| Community | ✅ 83k+ weekly downloads | ❌ Minimal adoption |
| Migration effort | ✅ Drop-in (hours) | ❌ Full rewrite (weeks) |

**Conclusion**: isar_community 3.3.2 is the **only viable production choice** today.

---

## 2. Technical & Stability Reasons

### Compatibility
| Requirement | Status |
|---|---|
| Dart SDK 3.9+ | ✅ Supported |
| Flutter latest | ✅ Supported |
| Android / iOS / Windows / macOS / Linux | ✅ All platforms |
| Web | ✅ Supported |
| `build_runner` compatibility | ✅ Works with latest `build_runner` AOT |

### Stability Improvements Over Original Isar 3.1.0+1
- Fixed crash on Windows (native port handling)
- Fixed "IndexNotFound" error
- Fixed native ports not closed correctly
- Added arm64 iOS Simulator support
- Updated analyzer dependency (compatible with Dart 3.x series)
- Inspector now supports creating objects and importing JSON

### Risk Assessment
- **Regression risk**: Minimal — identical API surface, same generated schema format
- **Obsolescence risk**: Low — even if isar_community stops, the 3.x API is frozen and well-documented. A migration to any other database (Hive CE, ObjectBox, Drift) is bounded and predictable.
- **Security risk**: None introduced — the codebase is open-source Apache 2.0

---

## 3. Suitability for Long-Term Commercial Production

### ✅ Yes, with Mitigations

**Strengths:**
- Proven in production by thousands of apps (original Isar was 2.4k+ likes)
- Community fork addresses the original project's abandonment
- Encapsulated behind `DatabaseService` abstraction — not tightly coupled

**Mitigations for Commercial Risk:**

| Risk | Mitigation |
|---|---|
| Community project (no SLA) | Abstracted behind `DatabaseService` — swap possible in weeks, not months |
| No commercial backing | OS-level encryption + independent `EncryptionService` protect data regardless of DB choice |
| Future API breakage | All Isar usage confined to `database/` package; no leakage into features or UI |
| Need for advanced features (FTS, relations) | Isar 3.x supports full-text search, indexes, links, embedded objects — meets all current requirements |

**Trade-off Accepted**: Using a community fork is a calculated risk. The abstraction layer ensures this risk is **contained and reversible**.

---

## 4. Future Migration to Isar 4 (When Stable)

If a stable Isar 4 is released and meets all project requirements, migration is **bounded and predictable**.

### Migration Plan

```
┌─────────────────────────────────────────────────────────┐
│                   Migration Path                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Evaluate Isar 4 stable release                       │
│     - Review breaking changes, API diff                  │
│     - Check encryption support (if added)                │
│     - Verify all platforms still supported               │
│                                                          │
│  2. Update pubspec.yaml                                  │
│     isar_community → isar (or isar_4)                    │
│     isar_community_flutter_libs → isar_flutter_libs      │
│     isar_community_generator → isar_generator            │
│                                                          │
│  3. Regenerate schemas                                    │
│     dart run build_runner build                          │
│     (possibly new annotation format, generator output)   │
│                                                          │
│  4. Update DatabaseService if API changed                 │
│     - Transaction syntax                                 │
│     - Query API (where/filter)                           │
│     - Link handling                                      │
│                                                          │
│  5. Test & Validate                                      │
│     - All unit tests pass                                │
│     - Offline sync works                                 │
│     - Background sync works                              │
│     - Performance regression check                       │
│                                                          │
│  6. Staged Rollout                                       │
│     - Feature flag or phased OTA                         │
│     - Monitor crash rates & sync health                  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Estimated Effort**: 2–5 days (depending on API breakage magnitude)

**Why Migration Is Low-Risk:**
- `DatabaseService` centralizes all Isar calls
- `OfflineCache` and `SyncEngine` work through `DatabaseService`
- Repositories depend on `DatabaseService`, not directly on Isar
- Collection models are annotated with `@collection` — portable to any schema-based DB

---

## 5. Encryption Layer Independence ✅

### Confirmed: AES-256-GCM is Fully Independent of Isar

```
┌──────────────────────────────────────────────────────────────────┐
│                        Application Layer                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────────────┐    ┌──────────────────────────────┐   │
│   │    Repositories      │    │      Sync Engine             │   │
│   │    Use Cases         │    │      Offline Cache           │   │
│   └────────┬─────────────┘    └──────────┬───────────────────┘   │
│            │                             │                        │
│            ▼                             ▼                        │
│   ┌──────────────────────────────────────────────────────────┐   │
│   │                 DatabaseService                          │   │
│   │     (Centralized data access — all Isar calls here)      │   │
│   └────────┬──────────────────────────────────┬──────────────┘   │
│            │                                  │                  │
│            ▼                                  ▼                  │
│   ┌─────────────────┐              ┌─────────────────────┐      │
│   │   Isar 3.x DB   │              │   EncryptionService │      │
│   │  (local storage)│              │   (AES-256-GCM)     │      │
│   │                 │              │                     │      │
│   │   No encryption │    ───►      │   encrypt()         │      │
│   │   built-in      │      │       │   decrypt()         │      │
│   └─────────────────┘      │       │                     │      │
│                            │       │   Key: SHA-256 hash │      │
│                            │       │   Store: SecureStorage     │
│                            │       └─────────────────────┘      │
│                            ▼                                    │
│                      ┌──────────────────┐                       │
│                      │ Encrypted Data   │                       │
│                      │ in OfflineCache  │                       │
│                      │ & SyncQueue      │                       │
│                      └──────────────────┘                       │
└──────────────────────────────────────────────────────────────────┘
```

### Key Properties

| Property | Detail |
|---|---|
| Algorithm | **AES-256-GCM** (authenticated encryption) |
| Key derivation | SHA-256 of master password/seed |
| Key storage | `flutter_secure_storage` (platform keychain/keystore) |
| Dependency on Isar | **Zero** — `EncryptionService` has no Isar imports |
| Data flow | `DatabaseService` calls `EncryptionService` before writing, after reading |
| Replaceability | Swap Isar → Drift/SQLite/ObjectBox without touching a single line of encryption code |
| Scope | Sensitive fields in OfflineCache + SyncQueue data; Isar at-rest data relies on OS-level file encryption |

### Verification

```dart
// EncryptionService — zero Isar dependencies
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// No Isar import here ✅
```

---

## Final Decision

> **Adopt `isar_community` 3.3.2 as the local database solution, with an independent AES-256-GCM encryption layer via `EncryptionService`.**
>
> The project is officially ready for **Phase 6**.

### ADR Metadata

- **Author**: Architecture Review Board
- **Review Frequency**: Re-evaluate when Isar 4 stable is published, or when `isar_community` becomes unmaintained (>12 months without release)
- **Trigger for Revisit**: Stable Isar 4 release, or critical bug in isar_community requiring fork
