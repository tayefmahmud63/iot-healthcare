import 'package:flutter/material.dart';
import 'package:iot/widget.dart';
import 'package:iot/theme/iot_theme.dart';
import 'package:iot/screens/login_screen.dart';
import 'package:iot/services/auth_service.dart';
import 'package:iot/services/firebase_database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:iot/services/pdf_service.dart';
import 'package:iot/screens/settings/metric_editor_sheet.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT HealthCare',
      debugShowCheckedModeBanner: false,
      theme: IoTTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {'/home': (context) => const HomeScreen()},
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    IoTTheme.lightBackground,
                    IoTTheme.primaryBlue.withOpacity(0.1),
                  ],
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class EditPage extends StatelessWidget {
  final List<MetricDefinition> definitions;
  final Map<String, bool> metricEnabled;
  final List<String> metricOrder;
  final void Function(String id, bool value)? onToggleById;
  final void Function(List<String>)? onReorder;
  final VoidCallback? onAddMetric;
  final void Function(MetricDefinition definition)? onEditMetric;
  final void Function(MetricDefinition definition)? onDeleteMetric;
  final VoidCallback? onReset;

  const EditPage({
    Key? key,
    required this.definitions,
    required this.metricEnabled,
    required this.metricOrder,
    this.onToggleById,
    this.onReorder,
    this.onAddMetric,
    this.onEditMetric,
    this.onDeleteMetric,
    this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final definitionsById = {for (var d in definitions) d.id: d};
    final ordered = metricOrder
        .map((id) => definitionsById[id])
        .where((d) => d != null)
        .cast<MetricDefinition>()
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddMetric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IoTTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add widget',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: ordered.length,
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              final ids = List<String>.from(metricOrder);
              if (newIndex > oldIndex) newIndex -= 1;
              final item = ids.removeAt(oldIndex);
              ids.insert(newIndex, item);
              if (onReorder != null) onReorder!(ids);
            },
            itemBuilder: (context, index) {
              final definition = ordered[index];
              final enabled = metricEnabled[definition.id] ?? true;
              return Container(
                key: ValueKey(definition.id),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: IoTTheme.borderColor, width: 1),
                  boxShadow: IoTTheme.cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: definition.iconColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          definition.icon,
                          color: definition.iconColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              definition.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Firebase key: ${definition.firebaseField}',
                              style: TextStyle(
                                color: IoTTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _TypeInfoTile(
                              label: _typeLabel(definition.visualType),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: enabled,
                            onChanged: (value) =>
                                onToggleById?.call(definition.id, value),
                            activeColor: IoTTheme.primaryBlue,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 36,
                                width: 36,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  tooltip: 'More actions',
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 22,
                                    color: IoTTheme.darkBackground,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      onEditMetric?.call(definition);
                                    } else if (value == 'delete') {
                                      onDeleteMetric?.call(definition);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    if (definition.isCustom)
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              ReorderableDragStartListener(
                                index: index,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: IoTTheme.borderColor.withOpacity(
                                      0.4,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.drag_indicator_rounded,
                                    size: 20,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _typeLabel(MetricVisualType type) {
    switch (type) {
      case MetricVisualType.gauge:
        return 'Gauge';
      case MetricVisualType.chart:
        return 'Chart';
      case MetricVisualType.standard:
        return 'Card';
      case MetricVisualType.button:
        return 'Button';
      case MetricVisualType.pushButton:
        return 'Push Button';
    }
  }
}

class _TypeInfoTile extends StatelessWidget {
  final String label;

  const _TypeInfoTile({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IoTTheme.borderColor),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TYPE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: IoTTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: IoTTheme.darkBackground,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final FirebaseDatabaseService _firebaseService = FirebaseDatabaseService();
  int _selectedIndex = 0;
  List<MetricDefinition> _metricDefinitions = List<MetricDefinition>.from(
    defaultMetricDefinitions,
  );
  List<String> _metricOrder = [];
  final Map<String, bool> _metricEnabled = {};
  static const String _customDefinitionsKey = 'custom_metric_definitions';
  static const String _overrideDefinitionsKey = 'override_metric_definitions';
  static const String _metricOrderKey = 'metric_order_ids';
  bool _settingsReady = false;

  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _metricOrder = _metricDefinitions.map((m) => m.id).toList();
    for (final def in _metricDefinitions) {
      _metricEnabled.putIfAbsent(def.id, () => true);
    }
    _initializeFirebase();
    _loadPrefs();
  }

  Future<void> _initializeFirebase() async {
    await _firebaseService.initializeDefaultMetrics();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final overrides = _readDefinitionsFromPrefs(_overrideDefinitionsKey);
    final custom = _readDefinitionsFromPrefs(_customDefinitionsKey);

    final base = List<MetricDefinition>.from(defaultMetricDefinitions);
    for (final override in overrides) {
      final index = base.indexWhere((element) => element.id == override.id);
      if (index != -1) {
        base[index] = override.copyWith(isCustom: false, isUserOverride: true);
      }
    }

    final customDefs = custom
        .map(
          (def) =>
              def.copyWith(isCustom: true, isUserOverride: def.isUserOverride),
        )
        .toList();

    _metricDefinitions = [...base, ...customDefs];

    _metricOrder = _prefs?.getStringList(_metricOrderKey) ?? [];
    if (_metricOrder.isEmpty) {
      final legacyOrder = _prefs?.getStringList('metric_order');
      if (legacyOrder != null && legacyOrder.isNotEmpty) {
        _metricOrder = _mapNamesToIds(legacyOrder, _metricDefinitions);
      }
    }
    _metricOrder = _normalizeOrder(_metricOrder, _metricDefinitions);

    _metricEnabled.clear();
    for (final def in _metricDefinitions) {
      final key = 'metric_enabled_${def.id}';
      bool? enabled = _prefs?.getBool(key);
      if (enabled == null) {
        final legacyKey = 'metric_enabled_${def.name}';
        if (_prefs?.containsKey(legacyKey) ?? false) {
          enabled = _prefs?.getBool(legacyKey);
        }
      }
      _metricEnabled[def.id] = enabled ?? true;
    }

    setState(() {
      _settingsReady = true;
    });
  }

  List<MetricDefinition> _readDefinitionsFromPrefs(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .whereType<Map>()
          .map((e) => MetricDefinition.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<String> _mapNamesToIds(List<String> names, List<MetricDefinition> defs) {
    final mapping = {for (final def in defs) def.name: def.id};
    final List<String> ids = [];
    for (final name in names) {
      final id = mapping[name];
      if (id != null) ids.add(id);
    }
    return ids;
  }

  List<String> _normalizeOrder(
    List<String> order,
    List<MetricDefinition> defs,
  ) {
    final available = defs.map((d) => d.id).toList();
    final filtered = order.where((id) => available.contains(id)).toList();
    for (final id in available) {
      if (!filtered.contains(id)) filtered.add(id);
    }
    return filtered;
  }

  Future<void> _persistDefinitions() async {
    if (_prefs == null) return;
    final overrides = _metricDefinitions
        .where((def) => !def.isCustom && def.isUserOverride)
        .map((def) => def.toJson())
        .toList();
    final custom = _metricDefinitions
        .where((def) => def.isCustom)
        .map((def) => def.toJson())
        .toList();
    await _prefs!.setString(_overrideDefinitionsKey, jsonEncode(overrides));
    await _prefs!.setString(_customDefinitionsKey, jsonEncode(custom));
  }

  Future<void> _persistMetricOrder() async {
    if (_prefs == null) return;
    await _prefs!.setStringList(_metricOrderKey, _metricOrder);
  }

  List<MetricBlock> _buildMetricsForExport(Map<String, dynamic>? firebaseData) {
    final allMetrics = metricsFromFirebase(
      firebaseData,
      _metricDefinitions,
      firebaseService: _firebaseService,
    );
    final metricsById = {for (final metric in allMetrics) metric.id: metric};
    return _metricOrder
        .where((id) => _metricEnabled[id] ?? true)
        .map((id) => metricsById[id])
        .whereType<MetricBlock>()
        .toList();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _updateMetricEnabled(String id, bool value) {
    setState(() {
      _metricEnabled[id] = value;
      _prefs?.setBool('metric_enabled_$id', value);
    });
  }

  void _updateMetricOrder(List<String> newOrder) {
    setState(() {
      _metricOrder = _normalizeOrder(
        List<String>.from(newOrder),
        _metricDefinitions,
      );
    });
    _persistMetricOrder();
  }

  Future<void> _handleAddMetric() async {
    final result = await showModalBottomSheet<MetricDefinition>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => MetricEditorSheet(
        firebaseService: _firebaseService,
      ),
    );
    if (result == null) return;

    final definition = result.copyWith(isCustom: true, isUserOverride: false);

    setState(() {
      _metricDefinitions.add(definition);
      _metricOrder = _normalizeOrder([
        ..._metricOrder,
        definition.id,
      ], _metricDefinitions);
      _metricEnabled[definition.id] = true;
    });

    _prefs?.setBool('metric_enabled_${definition.id}', true);

    await _persistDefinitions();
    await _persistMetricOrder();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${definition.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleEditMetric(MetricDefinition definition) async {
    final result = await showModalBottomSheet<MetricDefinition>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => MetricEditorSheet(
        firebaseService: _firebaseService,
        definition: definition,
      ),
    );
    if (result == null) return;

    setState(() {
      final index = _metricDefinitions.indexWhere((d) => d.id == definition.id);
      if (index != -1) {
        final updated = result.copyWith(
          isCustom: definition.isCustom,
          isUserOverride: definition.isCustom
              ? definition.isUserOverride
              : true,
        );
        _metricDefinitions[index] = updated;
      }
    });

    await _persistDefinitions();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated ${result.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDeleteMetric(MetricDefinition definition) async {
    if (!definition.isCustom) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove widget'),
            content: Text('Delete ${definition.name}? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: IoTTheme.accentPink,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() {
      _metricDefinitions.removeWhere((d) => d.id == definition.id);
      _metricOrder.removeWhere((id) => id == definition.id);
      _metricEnabled.remove(definition.id);
      _metricOrder = _normalizeOrder(_metricOrder, _metricDefinitions);
    });

    _prefs?.remove('metric_enabled_${definition.id}');

    await _persistDefinitions();
    await _persistMetricOrder();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${definition.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleResetMetrics() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset dashboard'),
            content: const Text(
              'This will restore the default cards and remove custom widgets. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: IoTTheme.primaryBlue,
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final previousIds = _metricDefinitions.map((d) => d.id).toList();

    setState(() {
      _metricDefinitions = List<MetricDefinition>.from(
        defaultMetricDefinitions,
      );
      _metricOrder = _metricDefinitions.map((d) => d.id).toList();
      _metricEnabled
        ..clear()
        ..addEntries(_metricDefinitions.map((d) => MapEntry(d.id, true)));
    });

    await _prefs?.remove(_customDefinitionsKey);
    await _prefs?.remove(_overrideDefinitionsKey);
    await _prefs?.remove(_metricOrderKey);
    for (final id in previousIds) {
      await _prefs?.remove('metric_enabled_$id');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dashboard reset to defaults'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportHomeScreen() async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final firebaseData = await _firebaseService.getMetricsData();
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'User';

      if (!mounted) return;
      Navigator.of(context).pop();

      bool hasPermission = true;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          final status = await Permission.photos.request();
          hasPermission = status.isGranted;
        } else if (sdkInt >= 30) {
          hasPermission = true;
        } else {
          final status = await Permission.storage.request();
          hasPermission = status.isGranted;
        }
      }

      if (!hasPermission && defaultTargetPlatform == TargetPlatform.android) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission is required to save PDF'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      Directory? directory;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 30) {
          directory = await getApplicationDocumentsDirectory();
        } else {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            directory = downloadsDir;
          } else {
            directory = await getExternalStorageDirectory();
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access storage directory')),
          );
        }
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) =>
            _buildExportDialog(ctx, firebaseData, directory, userEmail),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildExportDialog(
    BuildContext ctx,
    Map<String, dynamic>? firebaseData,
    Directory? directory,
    String userEmail,
  ) {
    if (directory == null) {
      return const SizedBox.shrink();
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: IoTTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: IoTTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Export Dashboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(ctx).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Export all your health metrics as PDF:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () async {
                Navigator.of(ctx).pop();
                await _savePdfToDevice(firebaseData, directory, userEmail);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: IoTTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: IoTTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.save,
                        color: IoTTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Save PDF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Save PDF to your device',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                Navigator.of(ctx).pop();
                await _sharePdf(firebaseData, directory, userEmail);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: IoTTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: IoTTheme.accentPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.share,
                        color: IoTTheme.accentPink,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share PDF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Share via apps or print',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePdfToDevice(
    Map<String, dynamic>? firebaseData,
    Directory directory,
    String userEmail,
  ) async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final metrics = _buildMetricsForExport(firebaseData);
      final file = await PdfService.generatePdfFile(
        metrics: metrics,
        userEmail: userEmail,
        directory: directory,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('PDF saved to ${file.path}')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf(
    Map<String, dynamic>? firebaseData,
    Directory directory,
    String userEmail,
  ) async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final metrics = _buildMetricsForExport(firebaseData);
      final file = await PdfService.generatePdfFile(
        metrics: metrics,
        userEmail: userEmail,
        directory: directory,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My IoT HealthCare Dashboard Report',
        subject: 'IoT Dashboard PDF Export',
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_heart, color: IoTTheme.primaryBlue, size: 22),
            const SizedBox(width: 8),
            const Text(
              'IoT HealthCare',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            offset: const Offset(0, 8),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: IoTTheme.primaryBlue.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: IoTTheme.primaryBlue,
                ),
              ),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                final authService = AuthService();
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              }
            },
            itemBuilder: (BuildContext context) {
              final user = FirebaseAuth.instance.currentUser;
              final email = user?.email ?? 'User';
              final displayName = email.split('@')[0];
    
              return [
                PopupMenuItem(
                  value: 'user',
                  enabled: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: IoTTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 18,
                              color: IoTTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color: IoTTheme.darkBackground,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: IoTTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 8),
                PopupMenuItem(
                  value: 'logout',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: IoTTheme.accentPink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.logout,
                          size: 16,
                          color: IoTTheme.accentPink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Container(
        color: IoTTheme.lightBackground,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedIndex == 0
              ? ReactiveHealthMetricsWidget(
                  key: const ValueKey('home'),
                  metricOrder: _metricOrder,
                  metricEnabled: _metricEnabled,
                  firebaseService: _firebaseService,
                  definitions: _metricDefinitions,
                )
              : _selectedIndex == 1
              ? Center(
                  key: const ValueKey('export'),
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: IoTTheme.borderColor,
                        width: 1,
                      ),
                      boxShadow: IoTTheme.cardShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: IoTTheme.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.picture_as_pdf,
                            size: 40,
                            color: IoTTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Export Dashboard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Export all health metrics as PDF',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: IoTTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf, size: 20),
                          label: const Text(
                            'Export as PDF',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _exportHomeScreen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: IoTTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : (_settingsReady
                    ? EditPage(
                        key: const ValueKey('edit'),
                        definitions: _metricDefinitions,
                        metricEnabled: _metricEnabled,
                        metricOrder: _metricOrder,
                        onToggleById: _updateMetricEnabled,
                        onReorder: _updateMetricOrder,
                        onAddMetric: _handleAddMetric,
                        onEditMetric: _handleEditMetric,
                        onDeleteMetric: _handleDeleteMetric,
                        onReset: _handleResetMetrics,
                      )
                    : const Center(child: CircularProgressIndicator())),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: IoTTheme.borderColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.upload_file_outlined),
              activeIcon: Icon(Icons.upload_file),
              label: 'Export',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune),
              activeIcon: Icon(Icons.tune_rounded),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: IoTTheme.primaryBlue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
    );
  }
}
