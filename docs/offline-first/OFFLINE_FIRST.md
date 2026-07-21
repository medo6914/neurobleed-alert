# Offline First Architecture

> Local-First Strategy — Phase 1 Baseline

---

## Core Principle

The app must remain fully functional without internet connectivity.
All critical features (viewing patients, vital signs, alerts) work offline.
Data syncs automatically when connectivity is restored.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           FLUTTER APP                                    │
│                                                                          │
│  ┌──────────────────────────────┐      ┌──────────────────────────────┐  │
│  │       UI Layer               │      │     Connectivity Monitor     │  │
│  │  (Read from Streams)         │◄─────│  (connectivity_plus)         │  │
│  └──────────┬───────────────────┘      └──────────────┬───────────────┘  │
│             │                                          │                  │
│  ┌──────────▼───────────────────┐      ┌──────────────▼───────────────┐  │
│  │    Repository Layer          │      │     Sync Engine              │  │
│  │  (Read/Write Orchestrator)   │◄─────│  (Automatic Conflict Res.)  │  │
│  │                              │      │                              │  │
│  │  getPatients():              │      │  syncPatients():            │  │
│  │    1. Read from Local        │      │    1. Pull remote changes   │  │
│  │    2. Return immediately     │      │    2. Push local changes    │  │
│  │    3. Trigger background sync│      │    3. Merge with LWW        │  │
│  └──────────┬───────────────────┘      └──────────────┬───────────────┘  │
│             │                                          │                  │
│  ┌──────────▼───────────────────┐      ┌──────────────▼───────────────┐  │
│  │    Local Data Source          │      │     Remote Data Source       │  │
│  │  (Isar Database)              │      │  (Dio HTTP + WebSocket)     │  │
│  │                              │      │                              │  │
│  │  patients: IsarCollection    │      │  GET /v1/patients/           │  │
│  │  readings: TimeSeries        │      │  POST /v1/readings/          │  │
│  │  alerts: IsarCollection      │      │  ws://server/ws/device       │  │
│  │  pending_actions: Queue      │      │                              │  │
│  └──────────────────────────────┘      └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Local Database: Isar

**Why Isar**:
| Criteria | Isar | Hive |
|----------|------|------|
| Speed | 5,000 ops/s | 3,000 ops/s |
| Queries | Complex filters, sorting | Key-value only |
| Relations | Link/Backlink | None |
| Type Safety | Code-gen | Dynamic |
| Memory | ~2MB | ~1MB |
| Web Support | ✅ (WASM) | ✅ |
| Time-series | ✅ Custom indexes | ❌ |

**Schema**:
```dart
@collection
class PatientModel {
  Id id = Isar.autoIncrement();
  late String uuid;                  // Server UUID
  late String fullName;
  late DateTime dateOfBirth;
  late String gender;
  String? phone;
  String? medicalConditions;
  String? medications;
  String? bloodType;
  String? allergies;
  late bool isActive;
  String? riskLevel;
  double? riskScore;
  late DateTime lastSyncedAt;

  @Index()
  late String? hospitalId;
}

@collection
class SensorReadingModel {
  Id id = Isar.autoIncrement();
  late String uuid;
  late String patientId;
  late DateTime timestamp;
  double? heartRate;
  double? spo2;
  double? systolicBp;
  double? diastolicBp;
  double? rso2;
  double? signalQuality;
  double? motionArtifact;
  double? riskScore;
  String? riskLevel;
  late bool isSynced;              // false until uploaded
}

@collection
class PendingAction {
  Id id = Isar.autoIncrement();
  late String actionType;           // 'create', 'update', 'acknowledge'
  late String endpoint;             // '/v1/patients/'
  late String payload;              // JSON string
  late DateTime createdAt;
  late int retryCount;
  String? lastError;
}
```

---

## 2. Sync Engine

### Sync Strategy: Last-Writer-Wins (LWW) with Timestamps

```
Sync Flow:
┌─────────┐     ┌─────────────┐     ┌──────────┐
│ App     │────→│ Sync Engine  │────→│ Remote   │
│ Starts  │     │              │     │ Server   │
└─────────┘     │              │     └──────────┘
                │  1. Push all │     ┌──────────┐
                │     pending  │────→│ POST     │
                │     actions  │     │ /sync    │
                │              │     └──────────┘
                │  2. Pull all │     ┌──────────┐
                │     remote   │────→│ GET      │
                │     changes  │     │ /sync    │
                │     (since   │     │ ?since=  │
                │     lastSync)│     └──────────┘
                │              │
                │  3. Merge    │
                │     LWW:     │
                │     newer    │
                │     timestamp│
                │     wins     │
                └─────────────┘
```

### Conflict Resolution

```dart
class SyncEngine {
  Future<void> resolveConflict({
    required Entity local,
    required Entity remote,
  }) async {
    // LWW: Compare updated_at timestamps
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      await pushToRemote(local);       // Local wins
    } else if (remote.updatedAt.isAfter(local.updatedAt)) {
      await applyRemoteUpdate(remote); // Remote wins
    } else {
      // Timestamps equal — compare versions
      if (local.version > remote.version) {
        await pushToRemote(local);
      } else {
        await applyRemoteUpdate(remote);
      }
    }
  }
}
```

### Sync Triggers

| Trigger | Action | Priority |
|---------|--------|----------|
| App foreground | Full sync | High |
| Connectivity restored | Full sync | High |
| Data mutation | Push single action | Medium |
| Timer (every 5 min) | Background sync | Low |
| Pull-to-refresh | Full sync | User-initiated |

---

## 3. Offline Queue

### Pending Actions Queue

```dart
class PendingAction {
  final String actionType;     // create_patient, update_reading, acknowledge_alert
  final String endpoint;       // API endpoint
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount = 0;
  String? lastError;

  // Retry with exponential backoff
  Duration get nextRetryDelay => Duration(
    seconds: pow(2, retryCount).toInt().clamp(1, 300),  // 1s → 5min max
  );
}
```

### Action Processing

```dart
class OfflineQueue {
  Future<void> processQueue() async {
    final pending = await isar.pendingActions.where().findAll();

    for (final action in pending) {
      try {
        switch (action.actionType) {
          case 'create_patient':
            await api.post(action.endpoint, data: action.payload);
          case 'acknowledge_alert':
            await api.patch('${action.endpoint}/${action.payload['id']}');
        }
        await isar.pendingActions.delete(action.id);  // Remove on success
      } catch (e) {
        action.retryCount++;
        action.lastError = e.toString();
        await isar.pendingActions.put(action);         // Update retry count
      }
    }
  }
}
```

---

## 4. Background Sync

```dart
class BackgroundSyncService {
  Timer? _timer;

  void start() {
    // Periodic sync every 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (await hasConnectivity()) {
        await syncEngine.fullSync();
      }
    });

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncEngine.fullSync();
      }
    });
  }

  Future<bool> hasConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void dispose() {
    _timer?.cancel();
  }
}
```

---

## 5. Offline UI States

```dart
// Connectivity status provider
enum ConnectivityStatus { online, offline, syncing }

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    if (result == ConnectivityResult.none) return ConnectivityStatus.offline;
    // Check if sync is in progress
    final isSyncing = ref.read(syncStateProvider);
    return isSyncing ? ConnectivityStatus.syncing : ConnectivityStatus.online;
  });
});
```

**UI Indicators**:
- **Online**: No indicator (normal state)
- **Offline**: Banner at top: "You are offline — showing cached data"
- **Syncing**: Small animated sync icon in app bar
- **Pending changes**: "X changes pending sync" badge in settings

---

## 6. Data Flow Diagram

```
User creates patient (OFFLINE)
         │
    Haptic feedback + Optimistic UI update
         │
    [1] Save to Isar local DB (immediate)
         │
    [2] Create PendingAction in queue
         │
    [3] Return success to UI (patient appears immediately)
         │
    ╔══════════════════════════════════════════════╗
    ║         WAITING FOR CONNECTIVITY              ║
    ╚══════════════════════════════════════════════╝
         │
    Connectivity restored
         │
    [4] Sync Engine wakes up
         │
    [5] Process PendingAction queue
         │
    [6] POST /v1/patients/ → Server creates patient
         │
    [7] Server returns with server UUID
         │
    [8] Update local record with server UUID, isSynced=true
         │
    [9] Notify UI of sync completion
```

---

## 7. Storage Size Estimates

| Data Type | Records/Patient/Day | Size/Record | Daily Growth | 30-Day Total |
|-----------|-------------------|-------------|-------------|--------------|
| Sensor Readings | 288 (1/5min) | 256 bytes | 72 KB | 2.1 MB |
| Patient Data | N/A | 2 KB | Static | 200 KB (100 patients) |
| Alerts | 5 | 512 bytes | 2.5 KB | 75 KB |
| Pending Actions | 10 (max) | 1 KB | Temporary | 10 KB |
| **Total per patient** | | | **75 KB/day** | **2.3 MB/month** |

**Conclusion**: 100 patients × 2.3 MB = 230 MB/month — easily handled by modern devices.
