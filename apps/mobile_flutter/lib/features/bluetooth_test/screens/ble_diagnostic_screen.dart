import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import '../models/ble_test_models.dart';
import '../providers/ble_test_providers.dart';
import '../widgets/ble_test_widgets.dart';

class BleDiagnosticScreen extends ConsumerStatefulWidget {
  const BleDiagnosticScreen({super.key});

  @override
  ConsumerState<BleDiagnosticScreen> createState() => _BleDiagnosticScreenState();
}

class _BleDiagnosticScreenState extends ConsumerState<BleDiagnosticScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _scanAnimation;
  String? _connectingDeviceId;
  final TextEditingController _writeController = TextEditingController();
  String _selectedUuidService = '';
  String _selectedUuidCharacteristic = '';
  Uint8List? _lastReadValue;
  String _readDisplayFormat = 'HEX';

  final List<String> _testPayloads = ['Hello', 'PING', 'TEST', '12345'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scanAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scanAnimation.dispose();
    _writeController.dispose();
    super.dispose();
  }

  Future<void> _initializeBle() async {
    final service = ref.read(bleTestServiceProvider);
    final success = await service.initialize();
    if (!mounted) return;
    if (!success) {
      _showSnack('BLE initialization failed', isError: true);
    }
  }

  Future<void> _enableBluetooth() async {
    final service = ref.read(bleTestServiceProvider);
    final success = await service.enableBluetooth();
    if (!mounted) return;
    if (!success) _showSnack('Failed to enable Bluetooth', isError: true);
  }

  Future<void> _requestPermissions() async {
    final service = ref.read(bleTestServiceProvider);
    final success = await service.requestPermissions();
    if (!mounted) return;
    if (!success) _showSnack('Permission request failed', isError: true);
  }

  Future<void> _startScan() async {
    final service = ref.read(bleTestServiceProvider);
    ref.read(bleTestScanStateProvider.notifier).state = true;
    _scanAnimation.repeat();
    await service.startScan();
  }

  Future<void> _stopScan() async {
    final service = ref.read(bleTestServiceProvider);
    await service.stopScan();
    ref.read(bleTestScanStateProvider.notifier).state = false;
    _scanAnimation.stop();
    _scanAnimation.reset();
  }

  Future<void> _connect(BleTestDevice device) async {
    setState(() {
      _connectingDeviceId = device.id;
    });
    final service = ref.read(bleTestServiceProvider);
    final success = await service.connectToDevice(device.id, deviceName: device.name);
    if (!mounted) return;
    setState(() {
      _connectingDeviceId = null;
    });
    if (!success) {
      _showSnack('Connection failed', isError: true);
    } else {
      _showSnack('Connected to ${device.name}');
    }
  }

  Future<void> _disconnect() async {
    final service = ref.read(bleTestServiceProvider);
    await service.disconnect();
    setState(() {
      _lastReadValue = null;
      _selectedUuidService = '';
      _selectedUuidCharacteristic = '';
    });
  }

  Future<void> _discoverServices() async {
    final service = ref.read(bleTestServiceProvider);
    final svcs = await service.discoverServices();
    if (!mounted) return;
    if (svcs.isNotEmpty) {
      _selectedUuidService = svcs.first.uuid;
      if (svcs.first.characteristics.isNotEmpty) {
        _selectedUuidCharacteristic = svcs.first.characteristics.first.uuid;
      }
      _showSnack('${svcs.length} services discovered');
    }
  }

  Future<void> _readCharacteristic() async {
    if (_selectedUuidService.isEmpty || _selectedUuidCharacteristic.isEmpty) {
      _showSnack('Select a service and characteristic first', isError: true);
      return;
    }
    final service = ref.read(bleTestServiceProvider);
    final value = await service.readCharacteristic(
      _selectedUuidService,
      _selectedUuidCharacteristic,
    );
    if (!mounted) return;
    setState(() => _lastReadValue = value);
  }

  Future<void> _writeTestData() async {
    if (_selectedUuidService.isEmpty || _selectedUuidCharacteristic.isEmpty) {
      _showSnack('Select a service and characteristic first', isError: true);
      return;
    }
    final text = _writeController.text.trim();
    if (text.isEmpty) {
      _showSnack('Enter data to write', isError: true);
      return;
    }
    final service = ref.read(bleTestServiceProvider);
    final data = Uint8List.fromList(utf8.encode(text));
    final success = await service.writeCharacteristic(
      _selectedUuidService,
      _selectedUuidCharacteristic,
      data,
    );
    if (!mounted) return;
    _showSnack(success ? 'Write successful' : 'Write failed', isError: !success);
  }

  Future<void> _enableNotifications() async {
    if (_selectedUuidService.isEmpty || _selectedUuidCharacteristic.isEmpty) {
      _showSnack('Select a characteristic first', isError: true);
      return;
    }
    final service = ref.read(bleTestServiceProvider);
    final success = await service.enableNotifications(
      _selectedUuidService,
      _selectedUuidCharacteristic,
    );
    if (!mounted) return;
    _showSnack(success ? 'Notifications enabled' : 'Failed to enable', isError: !success);
  }

  Future<void> _disableNotifications() async {
    final service = ref.read(bleTestServiceProvider);
    await service.disableNotifications(_selectedUuidCharacteristic);
  }

  void _clearLogs() {
    ref.read(bleTestServiceProvider).clearLogs();
  }

  Future<void> _copyLogs() async {
    final logs = ref.read(bleTestServiceProvider).exportLogs();
    await Clipboard.setData(ClipboardData(text: logs));
    if (!mounted) return;
    _showSnack('Logs copied to clipboard');
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? NeuroColors.critical : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(bleTestScanStateProvider);
    final status = ref.watch(bleTestStatusProvider);
    final connectionState = ref.watch(bleTestConnectionStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Diagnostic'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Status', icon: Icon(Icons.info_outline, size: 18)),
            Tab(text: 'Scan', icon: Icon(Icons.search, size: 18)),
            Tab(text: 'Services', icon: Icon(Icons.list_alt, size: 18)),
            Tab(text: 'Logs', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatusTab(theme, status, connectionState),
          _buildScanTab(theme, isScanning),
          _buildServicesTab(theme),
          _buildLogsTab(theme),
        ],
      ),
    );
  }

  Widget _buildStatusTab(ThemeData theme, ({
    bool initialized,
    bool bleEnabled,
    bool locationPermission,
    bool nearbyPermission,
    bool scanning,
  }) status, AsyncValue<BleTestConnectionState> connectionState) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(NeuroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: NeuroSpacing.sm),
          _StatusRow(icon: Icons.bluetooth, label: 'Bluetooth', value: status.bleEnabled, theme: theme),
          _StatusRow(icon: Icons.location_on, label: 'Location Permission', value: status.locationPermission, theme: theme),
          _StatusRow(icon: Icons.near_me, label: 'Nearby Devices Permission', value: status.nearbyPermission, theme: theme),
          _StatusRow(icon: Icons.bluetooth_searching, label: 'Scan Status', value: status.scanning, theme: theme),
          _StatusRow(icon: Icons.check_circle, label: 'Service Initialized', value: status.initialized, theme: theme),
          SizedBox(height: NeuroSpacing.lg),
          Text('Connection', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: NeuroSpacing.sm),
          SizedBox(height: 220, child: ConnectionPanel()),
          connectionState.when(
            loading: () => SizedBox.shrink(),
            error: (e, _) => SizedBox.shrink(),
            data: (state) {
              final connectionInfo = ref.watch(bleTestConnectedDeviceInfoProvider);
              if (connectionInfo.state == BleTestConnectionState.connected) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: NeuroSpacing.sm),
                    Text('Services: ${ref.watch(bleTestServicesProvider).valueOrNull?.length ?? 0}'),
                    SizedBox(height: NeuroSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Discover Services',
                            icon: Icons.explore,
                            onPressed: _discoverServices,
                          ),
                        ),
                        SizedBox(width: NeuroSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: 'Disconnect',
                            icon: Icons.link_off,
                            variant: ButtonVariant.secondary,
                            onPressed: _disconnect,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return SizedBox.shrink();
            },
          ),
          SizedBox(height: NeuroSpacing.lg),
          Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: NeuroSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: Icon(Icons.bluetooth, size: 16),
                label: const Text('Enable BT'),
                onPressed: _enableBluetooth,
              ),
              ActionChip(
                avatar: Icon(Icons.security, size: 16),
                label: const Text('Permissions'),
                onPressed: _requestPermissions,
              ),
              ActionChip(
                avatar: Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                onPressed: _initializeBle,
              ),
              ActionChip(
                avatar: Icon(Icons.delete_sweep, size: 16),
                label: const Text('Clear Log'),
                onPressed: _clearLogs,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanTab(ThemeData theme, bool isScanning) {
    final devicesAsync = ref.watch(bleTestScannedDevicesProvider);
    final service = ref.read(bleTestServiceProvider);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(NeuroSpacing.md),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isScanning ? 60 + _scanAnimation.value * 20 : 60,
                    height: isScanning ? 60 + _scanAnimation.value * 20 : 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(
                        alpha: isScanning ? 0.3 - (_scanAnimation.value * 0.2) : 0.1,
                      ),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: isScanning ? 0.6 - (_scanAnimation.value * 0.4) : 0.3,
                        ),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: NeuroSpacing.sm),
              Text(
                isScanning ? 'Scanning for devices...' : 'Tap Scan to discover devices',
                style: theme.textTheme.bodySmall,
              ),
              SizedBox(height: NeuroSpacing.sm),
              devicesAsync.when(
                loading: () => SizedBox.shrink(),
                error: (e, _) => SizedBox.shrink(),
                data: (devices) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isScanning)
                        AppButton(
                          label: 'Stop Scan',
                          icon: Icons.stop,
                          variant: ButtonVariant.secondary,
                          onPressed: _stopScan,
                        )
                      else
                        AppButton(
                          label: 'Start Scan',
                          icon: Icons.search,
                          onPressed: _startScan,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Divider(height: 1),
        Expanded(
          child: devicesAsync.when(
            loading: () => Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, _) => AppErrorState(title: 'Scan Error', message: e.toString(), onRetry: _startScan),
            data: (devices) {
              if (!isScanning && devices.isEmpty) {
                return AppEmptyState(
                  icon: Icons.bluetooth_disabled,
                  title: 'Not Scanning',
                  message: 'Tap "Start Scan" to discover nearby BLE devices.',
                );
              }
              if (devices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(height: NeuroSpacing.sm),
                      Text('Searching...', style: theme.textTheme.bodySmall),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(NeuroSpacing.md),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
                    child: BleTestDeviceCard(
                      device: device,
                      isConnecting: _connectingDeviceId == device.id,
                      onConnect: service.connectionState == BleTestConnectionState.connected
                          ? null
                          : () => _connect(device),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesTab(ThemeData theme) {
    final servicesAsync = ref.watch(bleTestServicesProvider);
    final connectionState = ref.watch(bleTestConnectionStateProvider);

    return connectionState.when(
      loading: () => Center(child: Text('Loading...', style: theme.textTheme.bodySmall)),
      error: (e, _) => AppErrorState(title: 'Error', message: e.toString()),
      data: (state) {
        if (state != BleTestConnectionState.connected) {
          return AppEmptyState(
            icon: Icons.bluetooth_disabled,
            title: 'Not Connected',
            message: 'Connect to a device to browse services and characteristics.',
            actionLabel: 'Go to Scan',
            onAction: () => _tabController.animateTo(1),
          );
        }

        final services = servicesAsync.valueOrNull ?? [];
        if (_selectedUuidService.isEmpty && services.isNotEmpty) {
          _selectedUuidService = services.first.uuid;
          if (services.first.characteristics.isNotEmpty) {
            _selectedUuidCharacteristic = services.first.characteristics.first.uuid;
          }
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(NeuroSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Discover Services',
                      icon: Icons.explore,
                      onPressed: _discoverServices,
                    ),
                  ),
                  SizedBox(width: NeuroSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Refresh',
                      icon: Icons.refresh,
                      variant: ButtonVariant.secondary,
                      onPressed: _discoverServices,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: servicesAsync.when(
                loading: () => Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => AppErrorState(title: 'Error', message: e.toString()),
                data: (services) {
                  if (services.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.list_alt,
                      title: 'No Services',
                      message: 'Tap "Discover Services" to load the GATT profile.',
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ServiceExplorer(),
                      ),
                      Divider(height: 1),
                      Expanded(
                        flex: 2,
                        child: _buildCharacteristicActions(theme, services),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharacteristicActions(ThemeData theme, List<BleTestServiceInfo> services) {
    final serviceUuids = services.map((s) => s.uuid).toList();
    final characteristics = services.expand((s) => s.characteristics).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(NeuroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Characteristic Actions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: NeuroSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: serviceUuids.contains(_selectedUuidService) ? _selectedUuidService : null,
                  decoration: InputDecoration(
                    labelText: 'Service',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: serviceUuids.map((uuid) => DropdownMenuItem(
                    value: uuid,
                    child: Text('0x${uuid.toUpperCase()}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedUuidService = v;
                        final svc = services.where((s) => s.uuid == v).firstOrNull;
                        if (svc != null && svc.characteristics.isNotEmpty) {
                          _selectedUuidCharacteristic = svc.characteristics.first.uuid;
                        }
                      });
                    }
                  },
                ),
              ),
              SizedBox(width: NeuroSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: characteristics.any((c) => c.uuid == _selectedUuidCharacteristic)
                      ? _selectedUuidCharacteristic
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Characteristic',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: characteristics.map((ch) => DropdownMenuItem(
                    value: ch.uuid,
                    child: Text('0x${ch.uuid.toUpperCase()}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedUuidCharacteristic = v);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: NeuroSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ActionChip(
                avatar: Icon(Icons.download, size: 14),
                label: const Text('Read'),
                onPressed: _readCharacteristic,
                visualDensity: VisualDensity.compact,
              ),
              ActionChip(
                avatar: Icon(Icons.notifications, size: 14),
                label: const Text('Notify On'),
                onPressed: _enableNotifications,
                visualDensity: VisualDensity.compact,
              ),
              ActionChip(
                avatar: Icon(Icons.notifications_off, size: 14),
                label: const Text('Notify Off'),
                onPressed: _disableNotifications,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: NeuroSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _writeController,
                  decoration: InputDecoration(
                    labelText: 'Write data',
                    hintText: 'Enter text to write...',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: NeuroSpacing.sm),
              PopupMenuButton<String>(
                onSelected: (v) => _writeController.text = v,
                itemBuilder: (_) => _testPayloads.map((p) => PopupMenuItem(value: p, child: Text(p))).toList(),
                child: Icon(Icons.history),
              ),
              SizedBox(width: NeuroSpacing.sm),
              AppButton(
                label: 'Write',
                icon: Icons.send,
                variant: ButtonVariant.secondary,
                onPressed: _writeTestData,
              ),
            ],
          ),
          if (_lastReadValue != null) ...[
            SizedBox(height: NeuroSpacing.sm),
            AppCard(
              child: Padding(
                padding: EdgeInsets.all(NeuroSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Read Value', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Spacer(),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'HEX', label: Text('HEX', style: TextStyle(fontSize: 10))),
                            ButtonSegment(value: 'ASCII', label: Text('ASCII', style: TextStyle(fontSize: 10))),
                            ButtonSegment(value: 'UTF8', label: Text('UTF8', style: TextStyle(fontSize: 10))),
                          ],
                          selected: {_readDisplayFormat},
                          onSelectionChanged: (v) => setState(() => _readDisplayFormat = v.first),
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatReadValue(_lastReadValue!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: NeuroSpacing.sm),
          NotificationViewer(),
        ],
      ),
    );
  }

  String _formatReadValue(Uint8List data) {
    return switch (_readDisplayFormat) {
      'HEX' => data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
      'ASCII' => String.fromCharCodes(data.where((b) => b >= 32 && b <= 126)),
      'UTF8' => utf8.decode(data, allowMalformed: true),
      _ => '',
    };
  }

  Widget _buildLogsTab(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(NeuroSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text('Operation Log', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              ActionChip(
                avatar: Icon(Icons.copy, size: 14),
                label: const Text('Copy'),
                onPressed: _copyLogs,
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(width: 4),
              ActionChip(
                avatar: Icon(Icons.delete_sweep, size: 14),
                label: const Text('Clear'),
                onPressed: _clearLogs,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Divider(height: 1),
        Expanded(child: BleTestLogViewer()),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ThemeData theme;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.xs),
      child: AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: NeuroSpacing.md, vertical: NeuroSpacing.sm),
          child: Row(
            children: [
              Icon(icon, size: 18, color: value ? NeuroColors.low : NeuroColors.critical),
              SizedBox(width: NeuroSpacing.sm),
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: value
                      ? NeuroColors.low.withValues(alpha: 0.15)
                      : NeuroColors.critical.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value ? 'ON' : 'OFF',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: value ? NeuroColors.low : NeuroColors.critical,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
