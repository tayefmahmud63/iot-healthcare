import 'package:flutter/material.dart';
import 'package:iot/gauge_widget.dart';
import 'package:iot/heart_rate_chart.dart';
import 'package:iot/button_widgets.dart';
import 'package:iot/services/firebase_database_service.dart';
import 'package:iot/theme/iot_theme.dart';

enum MetricVisualType { standard, gauge, chart, button, pushButton }

class MetricBlock {
  final MetricDefinition definition;
  final String value;
  final String unit;
  final Widget? customWidget;

  MetricBlock({
    required this.definition,
    this.value = '',
    this.unit = '',
    this.customWidget,
  });

  String get id => definition.id;
  String get name => definition.name;
  IconData get icon => definition.icon;
  Color get iconColor => definition.iconColor;
  bool get fullWidth => definition.fullWidth;
}

class HealthMetricsPage extends StatelessWidget {
  const HealthMetricsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Health Metrics'), elevation: 0),
      body: HealthMetricsWidget(
        items: metricsFromFirebase(null, defaultMetricDefinitions),
      ),
    );
  }
}

final List<MetricDefinition> defaultMetricDefinitions = [
  MetricDefinition(
    id: 'metric_heart_rate',
    name: 'Heart Rate',
    firebaseField: 'Heart Rate',
    icon: Icons.favorite,
    iconColor: Colors.blue,
    unit: 'BPM',
  ),
  MetricDefinition(
    id: 'metric_blood_pressure',
    name: 'Blood Pressure',
    firebaseField: 'Blood Pressure',
    icon: Icons.monitor_heart,
    iconColor: Colors.green,
    unit: 'mmHg',
  ),
  MetricDefinition(
    id: 'metric_temperature',
    name: 'Temperature',
    firebaseField: 'Temperature',
    icon: Icons.thermostat,
    iconColor: Colors.orange,
    unit: '°F',
  ),
  MetricDefinition(
    id: 'metric_oxygen',
    name: 'Oxygen Level',
    firebaseField: 'Oxygen Level',
    icon: Icons.air,
    iconColor: Colors.cyan,
    unit: '%',
  ),
  MetricDefinition(
    id: 'metric_steps',
    name: 'Steps',
    firebaseField: 'Steps',
    icon: Icons.directions_walk,
    iconColor: Colors.purple,
    unit: 'steps',
  ),
  MetricDefinition(
    id: 'metric_calories',
    name: 'Calories',
    firebaseField: 'Calories',
    icon: Icons.local_fire_department,
    iconColor: Colors.red,
    unit: 'kcal',
  ),
  MetricDefinition(
    id: 'metric_gauge',
    name: 'Gauge',
    firebaseField: 'Gauge',
    icon: Icons.speed,
    iconColor: Colors.teal,
    unit: '°C',
    fullWidth: true,
    visualType: MetricVisualType.gauge,
  ),
  MetricDefinition(
    id: 'metric_heart_rate_chart',
    name: 'Heart Rate Chart',
    firebaseField: 'Heart Rate',
    icon: Icons.show_chart,
    iconColor: Colors.red,
    unit: 'BPM',
    fullWidth: true,
    visualType: MetricVisualType.chart,
  ),
];

class MetricDefinition {
  final String id;
  final String name;
  final String firebaseField;
  final IconData icon;
  final Color iconColor;
  final String unit;
  final MetricVisualType visualType;
  final bool fullWidth;
  final bool isCustom;
  final bool isRadialGauge;
  final double? minValue;
  final double? maxValue;
  final bool isUserOverride;

  const MetricDefinition({
    required this.id,
    required this.name,
    required this.firebaseField,
    required this.icon,
    required this.iconColor,
    required this.unit,
    this.visualType = MetricVisualType.standard,
    this.fullWidth = false,
    this.isCustom = false,
    this.isRadialGauge = true,
    this.minValue,
    this.maxValue,
    this.isUserOverride = false,
  });

  MetricDefinition copyWith({
    String? id,
    String? name,
    String? firebaseField,
    IconData? icon,
    Color? iconColor,
    String? unit,
    MetricVisualType? visualType,
    bool? fullWidth,
    bool? isCustom,
    bool? isRadialGauge,
    double? minValue,
    double? maxValue,
    bool? isUserOverride,
  }) {
    return MetricDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      firebaseField: firebaseField ?? this.firebaseField,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      unit: unit ?? this.unit,
      visualType: visualType ?? this.visualType,
      fullWidth: fullWidth ?? this.fullWidth,
      isCustom: isCustom ?? this.isCustom,
      isRadialGauge: isRadialGauge ?? this.isRadialGauge,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      isUserOverride: isUserOverride ?? this.isUserOverride,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'firebaseField': firebaseField,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'iconColor': iconColor.value,
      'unit': unit,
      'visualType': visualType.name,
      'fullWidth': fullWidth,
      'isCustom': isCustom,
      'isRadialGauge': isRadialGauge,
      'minValue': minValue,
      'maxValue': maxValue,
      'isUserOverride': isUserOverride,
    };
  }

  factory MetricDefinition.fromJson(Map<String, dynamic> json) {
    return MetricDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      firebaseField: json['firebaseField'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
        matchTextDirection: false,
      ),
      iconColor: Color(json['iconColor'] as int),
      unit: json['unit'] as String,
      visualType: MetricVisualType.values.firstWhere(
        (v) => v.name == json['visualType'],
        orElse: () => MetricVisualType.standard,
      ),
      fullWidth: json['fullWidth'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? true,
      isRadialGauge: json['isRadialGauge'] as bool? ?? true,
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
      isUserOverride: json['isUserOverride'] as bool? ?? false,
    );
  }
}

List<MetricBlock> metricsFromFirebase(
  Map<String, dynamic>? firebaseData,
  List<MetricDefinition> definitions, {
  FirebaseDatabaseService? firebaseService,
}) {
  return definitions.map((def) {
    final data = firebaseData?[def.firebaseField];

    switch (def.visualType) {
      case MetricVisualType.gauge:
        final double gaugeValue = _extractDouble(data) ?? 0;
        final String gaugeUnit = _extractUnit(data, def.unit);
        return MetricBlock(
          definition: def,
          customWidget: GaugeWidget(
            title: def.name,
            value: gaugeValue,
            unit: gaugeUnit,
            minValue: def.minValue ?? 0,
            maxValue: def.maxValue ?? 100,
            isRadialGauge: def.isRadialGauge,
            accentColor: def.iconColor,
          ),
        );
      case MetricVisualType.chart:
        final String? chartValue = data == null ? null : _extractString(data);
        final String? timestamp = _extractTimestamp(data);
        return MetricBlock(
          definition: def,
          customWidget: HeartRateChart(
            dataSource: def.firebaseField,
            title: def.name,
            unit: def.unit,
            lineColor: def.iconColor,
            heartRateValue: chartValue,
            heartRateTimestamp: timestamp,
            firebaseService: firebaseService,
          ),
        );
      case MetricVisualType.button:
        if (firebaseService != null) {
          return MetricBlock(
            definition: def,
            customWidget: ToggleButtonWidget(
              title: def.name,
              firebaseField: def.firebaseField,
              icon: def.icon,
              accentColor: def.iconColor,
              firebaseService: firebaseService,
            ),
          );
        }
        return MetricBlock(definition: def);
      case MetricVisualType.pushButton:
        if (firebaseService != null) {
          return MetricBlock(
            definition: def,
            customWidget: PushButtonWidget(
              title: def.name,
              firebaseField: def.firebaseField,
              icon: def.icon,
              accentColor: def.iconColor,
              firebaseService: firebaseService,
            ),
          );
        }
        return MetricBlock(definition: def);
      case MetricVisualType.standard:
        final value = _extractString(data);
        final unit = _extractUnit(data, def.unit);
        return MetricBlock(definition: def, value: value, unit: unit);
    }
  }).toList();
}

double? _extractDouble(dynamic data) {
  if (data == null) return null;
  if (data is Map) {
    if (data['value'] != null) {
      return double.tryParse(data['value'].toString());
    }
    if (data['temperature'] != null) {
      return double.tryParse(data['temperature'].toString());
    }
  }
  if (data is num) return data.toDouble();
  return double.tryParse(data.toString());
}

String _extractString(dynamic data, {String fallback = '0'}) {
  if (data == null) return fallback;
  if (data is Map) {
    if (data['value'] != null) return data['value'].toString();
  }
  return data.toString();
}

String _extractUnit(dynamic data, String fallback) {
  if (data is Map && data['unit'] != null) {
    return data['unit'].toString();
  }
  return fallback;
}

String? _extractTimestamp(dynamic data) {
  if (data is Map && data['timestamp'] != null) {
    return data['timestamp'].toString();
  }
  return null;
}

class HealthMetricsWidget extends StatelessWidget {
  final List<MetricBlock> items;

  const HealthMetricsWidget({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
      child: Column(children: _buildRows()),
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
  final List<MetricDefinition> definitions;

  const ReactiveHealthMetricsWidget({
    Key? key,
    required this.metricOrder,
    required this.metricEnabled,
    required this.firebaseService,
    required this.definitions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: firebaseService.watchMetricsData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
        final allMetrics = metricsFromFirebase(
          firebaseData,
          definitions,
          firebaseService: firebaseService,
        );
        final metricsById = {for (var m in allMetrics) m.id: m};
        final filteredMetrics = metricOrder
            .where((id) => metricEnabled[id] ?? true)
            .map((id) => metricsById[id])
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

class _MetricCardState extends State<MetricCard>
    with SingleTickerProviderStateMixin {
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
            border: Border.all(color: IoTTheme.borderColor, width: 1),
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
