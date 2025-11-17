import 'package:flutter/material.dart';
import 'package:iot/gauge_widget.dart';
import 'package:iot/heart_rate_chart.dart';
import 'package:iot/services/firebase_database_service.dart';
import 'package:iot/theme/iot_theme.dart';

class MetricBlock {
  final String name;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final bool fullWidth;
  final Widget? customWidget;

  MetricBlock({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    this.fullWidth = false,
    this.customWidget,
  });
}

class HealthMetricsPage extends StatelessWidget {
  const HealthMetricsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Health Metrics'),
        elevation: 0,
      ),
      body: HealthMetricsWidget(
        items: metricsFromFirebase(null),
      ),
    );
  }
}

final List<MetricDefinition> metricDefinitions = [
  MetricDefinition(
    name: 'Heart Rate',
    icon: Icons.favorite,
    iconColor: Colors.blue,
    unit: 'BPM',
  ),
  MetricDefinition(
    name: 'Blood Pressure',
    icon: Icons.monitor_heart,
    iconColor: Colors.green,
    unit: 'mmHg',
  ),
  MetricDefinition(
    name: 'Temperature',
    icon: Icons.thermostat,
    iconColor: Colors.orange,
    unit: '°F',
  ),
  MetricDefinition(
    name: 'Oxygen Level',
    icon: Icons.air,
    iconColor: Colors.cyan,
    unit: '%',
  ),
  MetricDefinition(
    name: 'Steps',
    icon: Icons.directions_walk,
    iconColor: Colors.purple,
    unit: 'steps',
  ),
  MetricDefinition(
    name: 'Calories',
    icon: Icons.local_fire_department,
    iconColor: Colors.red,
    unit: 'kcal',
  ),
  MetricDefinition(
    name: 'Gauge',
    icon: Icons.speed,
    iconColor: Colors.teal,
    unit: '',
    fullWidth: true,
  ),
  MetricDefinition(
    name: 'Heart Rate Chart',
    icon: Icons.show_chart,
    iconColor: Colors.red,
    unit: '',
    fullWidth: true,
  ),
];

class MetricDefinition {
  final String name;
  final IconData icon;
  final Color iconColor;
  final String unit;
  final bool fullWidth;

  MetricDefinition({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.unit,
    this.fullWidth = false,
  });
}

List<MetricBlock> metricsFromFirebase(Map<String, dynamic>? firebaseData) {
  if (firebaseData == null) {
    return metricDefinitions.map((def) {
      if (def.fullWidth) {
        if (def.name == 'Gauge') {
          return MetricBlock(
            name: def.name,
            icon: def.icon,
            iconColor: def.iconColor,
            value: '',
            unit: def.unit,
            fullWidth: true,
            customWidget: GaugeWidget(
              temperature: 72.0,
              isRadialGauge: true,
            ),
          );
        } else if (def.name == 'Heart Rate Chart') {
          final heartRateData = firebaseData?['Heart Rate'];
          final heartRateValue = heartRateData != null && heartRateData is Map
              ? (heartRateData['value'] ?? '').toString()
              : null;
          final heartRateTimestamp = heartRateData != null && heartRateData is Map
              ? (heartRateData['timestamp'] ?? '').toString()
              : null;
          
          return MetricBlock(
            name: def.name,
            icon: def.icon,
            iconColor: def.iconColor,
            value: '',
            unit: def.unit,
            fullWidth: true,
            customWidget: HeartRateChart(
              dataSource: 'heartrate',
              heartRateValue: heartRateValue,
              heartRateTimestamp: heartRateTimestamp,
            ),
          );
        }
      }
      return MetricBlock(
        name: def.name,
        icon: def.icon,
        iconColor: def.iconColor,
        value: '0',
        unit: def.unit,
      );
    }).toList();
  }

  return metricDefinitions.map((def) {
    final data = firebaseData[def.name];
    
    if (def.fullWidth) {
      if (def.name == 'Gauge') {
        final temp = data != null && data is Map
            ? (data['temperature'] ?? 72.0).toDouble()
            : 72.0;
        return MetricBlock(
          name: def.name,
          icon: def.icon,
          iconColor: def.iconColor,
          value: '',
          unit: def.unit,
          fullWidth: true,
          customWidget: GaugeWidget(
            temperature: temp,
            isRadialGauge: true,
          ),
        );
      } else if (def.name == 'Heart Rate Chart') {
        final heartRateData = firebaseData['Heart Rate'];
        final heartRateValue = heartRateData != null && heartRateData is Map
            ? (heartRateData['value'] ?? '').toString()
            : null;
        final heartRateTimestamp = heartRateData != null && heartRateData is Map
            ? (heartRateData['timestamp'] ?? '').toString()
            : null;
        
        return MetricBlock(
          name: def.name,
          icon: def.icon,
          iconColor: def.iconColor,
          value: '',
          unit: def.unit,
          fullWidth: true,
          customWidget: HeartRateChart(
            dataSource: 'heartrate',
            heartRateValue: heartRateValue,
            heartRateTimestamp: heartRateTimestamp,
          ),
        );
      }
    }
    
    final value = data != null && data is Map
        ? (data['value'] ?? '0').toString()
        : '0';
    final unit = data != null && data is Map
        ? (data['unit'] ?? def.unit).toString()
        : def.unit;
    
    return MetricBlock(
      name: def.name,
      icon: def.icon,
      iconColor: def.iconColor,
      value: value,
      unit: unit,
    );
  }).toList();
}

class HealthMetricsWidget extends StatelessWidget {
  final List<MetricBlock> items;

  const HealthMetricsWidget({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
      child: Column(
        children: _buildRows(),
      ),
    );
  }

  List<Widget> _buildRows() {
    List<Widget> rows = [];
    int i = 0;
    while (i < items.length) {
      final item = items[i];
      if (item.fullWidth) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: item.customWidget ?? const SizedBox.shrink(),
          ),
        );
        i += 1;
      } else {
        if (i + 1 < items.length && !items[i + 1].fullWidth) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: MetricCard(metric: items[i])),
                  const SizedBox(width: 12),
                  Expanded(child: MetricCard(metric: items[i + 1])),
                ],
              ),
            ),
          );
          i += 2;
        } else {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: MetricCard(metric: items[i])),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          );
          i += 1;
        }
      }
    }

    return rows;
  }
}

class ReactiveHealthMetricsWidget extends StatelessWidget {
  final List<String> metricOrder;
  final Map<String, bool> metricEnabled;
  final FirebaseDatabaseService firebaseService;

  const ReactiveHealthMetricsWidget({
    Key? key,
    required this.metricOrder,
    required this.metricEnabled,
    required this.firebaseService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: firebaseService.watchMetricsData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading data: ${snapshot.error}',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ],
            ),
          );
        }

        final firebaseData = snapshot.data;
        final allMetrics = metricsFromFirebase(firebaseData);
        
        final filteredMetrics = metricOrder
            .where((name) => metricEnabled[name] ?? true)
            .map((name) {
              try {
                return allMetrics.firstWhere((m) => m.name == name);
              } catch (_) {
                return null;
              }
            })
            .where((m) => m != null)
            .cast<MetricBlock>()
            .toList();

        return HealthMetricsWidget(items: filteredMetrics);
      },
    );
  }
}



class MetricCard extends StatefulWidget {
  final MetricBlock metric;

  const MetricCard({Key? key, required this.metric}) : super(key: key);

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.metric.name,
                style: TextStyle(
                  fontSize: 12,
                  color: IoTTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.metric.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.metric.icon,
                  size: 28,
                  color: widget.metric.iconColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.metric.value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: IoTTheme.darkBackground,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.metric.unit,
                style: TextStyle(
                  fontSize: 11,
                  color: IoTTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
