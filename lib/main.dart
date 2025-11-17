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
import 'dart:io';

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
      routes: {
        '/home': (context) => const HomeScreen(),
      },
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
              child: const Center(
                child: CircularProgressIndicator(),
              ),
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
  final Map<String, bool> metricEnabled;
  final List<String> metricOrder;
  final void Function(String, bool)? onToggleByName;
  final void Function(List<String>)? onReorder;
  final FirebaseDatabaseService? firebaseService;

  const EditPage({
    Key? key,
    required this.metricEnabled,
    required this.metricOrder,
    this.onToggleByName,
    this.onReorder,
    this.firebaseService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: metricOrder.length,
        onReorder: (oldIndex, newIndex) {
          final list = List<String>.from(metricOrder);
          if (newIndex > oldIndex) newIndex -= 1;
          final item = list.removeAt(oldIndex);
          list.insert(newIndex, item);
          if (onReorder != null) onReorder!(list);
        },
        buildDefaultDragHandles: true,
        itemBuilder: (context, index) {
          final name = metricOrder[index];
          final m = metricDefinitions.firstWhere((mm) => mm.name == name);
          final isEnabled = metricEnabled[name] ?? true;
          return Container(
            key: ValueKey(name),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: IoTTheme.borderColor,
                width: 1,
              ),
              boxShadow: IoTTheme.cardShadow,
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: m.iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(m.icon, color: m.iconColor),
              ),
              title: Text(
                m.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: IoTTheme.darkBackground,
                ),
              ),
              trailing: Switch(
                value: isEnabled,
                onChanged: (v) {
                  if (onToggleByName != null) onToggleByName!(name, v);
                },
                activeColor: IoTTheme.primaryBlue,
              ),
            ),
          );
        },
      ),
    );
  }
}



class _HomeScreenState extends State<HomeScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final FirebaseDatabaseService _firebaseService = FirebaseDatabaseService();
  int _selectedIndex = 0;

  List<String> _metricOrder = metricDefinitions.map((m) => m.name).toList();

  final Map<String, bool> _metricEnabled = {for (var m in metricDefinitions) m.name: true};

  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _loadPrefs();
  }

  Future<void> _initializeFirebase() async {
    await _firebaseService.initializeDefaultMetrics();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();

    final savedOrder = _prefs?.getStringList('metric_order');
    if (savedOrder != null && savedOrder.isNotEmpty) {
      final names = metricDefinitions.map((m) => m.name).toSet();
      _metricOrder = savedOrder.where((n) => names.contains(n)).toList();
      for (var m in metricDefinitions) {
        if (!_metricOrder.contains(m.name)) _metricOrder.add(m.name);
      }
    }

    for (var m in metricDefinitions) {
      final key = 'metric_enabled_${m.name}';
      if (_prefs!.containsKey(key)) {
        _metricEnabled[m.name] = _prefs!.getBool(key) ?? true;
      }
    }

    setState(() {});
  }

  void _onItemTapped(int index) {
  setState(() => _selectedIndex = index);

  }

  void _updateMetricEnabledByName(String name, bool value) {
    setState(() {
      _metricEnabled[name] = value;
      _prefs?.setBool('metric_enabled_$name', value);
    });
  }

  void _updateMetricOrder(List<String> newOrder) {
    setState(() {
      _metricOrder = List<String>.from(newOrder);
      _prefs?.setStringList('metric_order', _metricOrder);
    });
  }

  Future<void> _exportHomeScreen() async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
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
        builder: (ctx) => _buildExportDialog(ctx, firebaseData, directory, userEmail),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
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
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final file = await PdfService.generatePdfFile(
        firebaseData,
        userEmail,
        directory,
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
                Expanded(
                  child: Text('PDF saved to ${file.path}'),
                ),
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
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final file = await PdfService.generatePdfFile(
        firebaseData,
        userEmail,
        directory,
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
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monitor_heart,
                color: IoTTheme.primaryBlue,
                size: 22,
              ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                onPressed: _exportHomeScreen,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: IoTTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                    : EditPage(
                        key: const ValueKey('edit'),
                        metricEnabled: _metricEnabled,
                        metricOrder: _metricOrder,
                        onToggleByName: _updateMetricEnabledByName,
                        onReorder: _updateMetricOrder,
                        firebaseService: _firebaseService,
                      ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: IoTTheme.borderColor,
                width: 1,
              ),
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
      ),
    );
  }
}
