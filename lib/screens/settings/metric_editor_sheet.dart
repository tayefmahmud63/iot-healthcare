import 'package:flutter/material.dart';
import 'package:iot/services/firebase_database_service.dart';
import 'package:iot/theme/iot_theme.dart';
import 'package:iot/widget.dart';

class MetricEditorSheet extends StatefulWidget {
  final FirebaseDatabaseService firebaseService;
  final MetricDefinition? definition;

  const MetricEditorSheet({
    Key? key,
    required this.firebaseService,
    this.definition,
  }) : super(key: key);

  @override
  State<MetricEditorSheet> createState() => _MetricEditorSheetState();
}

class _MetricEditorSheetState extends State<MetricEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _firebaseFieldController;
  late final TextEditingController _unitController;
  late MetricVisualType _selectedType;
  late bool _radialGauge;
  late IconData _selectedIcon;
  late Color _selectedColor;
  bool _isSaving = false;

  MetricDefinition? get editingDefinition => widget.definition;
  bool get isEditing => editingDefinition != null;
  bool get lockVisualType =>
      isEditing && !(editingDefinition?.isCustom ?? false);

  @override
  void initState() {
    super.initState();
    final def = editingDefinition;
    _nameController = TextEditingController(text: def?.name ?? '');
    _firebaseFieldController = TextEditingController(
      text: def?.firebaseField ?? '',
    );
    _unitController = TextEditingController(text: def?.unit ?? '');
    _selectedType = def?.visualType ?? MetricVisualType.standard;
    _radialGauge = def?.isRadialGauge ?? true;
    _selectedIcon = def?.icon ?? _iconChoices.first;
    _selectedColor = def?.iconColor ?? _colorChoices.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firebaseFieldController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final bool isCustom = editingDefinition?.isCustom ?? true;
    final bool isOverride = isCustom
        ? (editingDefinition?.isUserOverride ?? false)
        : true;
    final String id =
        editingDefinition?.id ??
        'metric_${DateTime.now().millisecondsSinceEpoch}';
    final updatedDefinition = MetricDefinition(
      id: id,
      name: _nameController.text.trim(),
      firebaseField: _firebaseFieldController.text.trim(),
      icon: _selectedIcon,
      iconColor: _selectedColor,
      unit: _unitController.text.trim(),
      visualType: _selectedType,
      fullWidth: _selectedType != MetricVisualType.standard,
      isCustom: isCustom,
      isRadialGauge: _radialGauge,
      isUserOverride: isOverride,
    );

    if (!mounted) return;
    Navigator.of(context).pop(updatedDefinition);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Widget' : 'Add Widget',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Widget title',
                    hintText: 'e.g. Hydration Level',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firebaseFieldController,
                  decoration: const InputDecoration(
                    labelText: 'Firebase field key',
                    hintText: 'Exactly as stored inside metrics/<key>',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Firebase key is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MetricVisualType>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Widget type'),
                  onChanged: lockVisualType
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                  items: MetricVisualType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_typeLabel(type)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    labelText: _selectedType == MetricVisualType.gauge
                        ? 'Label / Unit'
                        : 'Unit',
                    hintText: _selectedType == MetricVisualType.gauge
                        ? '°C, PSI, %, etc.'
                        : 'e.g. %',
                  ),
                  validator: (value) {
                    if (_selectedType == MetricVisualType.standard ||
                        _selectedType == MetricVisualType.chart) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Unit is required';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick styling',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: IoTTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _iconChoices.map((iconData) {
                    final selected = iconData == _selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = iconData),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: selected
                              ? IoTTheme.primaryBlue.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? IoTTheme.primaryBlue
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(iconData, color: IoTTheme.primaryBlue),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: _colorChoices.map((color) {
                    final selected = color.value == _selectedColor.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Colors.black87
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (_selectedType == MetricVisualType.gauge)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Radial'),
                          selected: _radialGauge,
                          onSelected: (value) =>
                              setState(() => _radialGauge = true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Linear'),
                          selected: !_radialGauge,
                          onSelected: (value) =>
                              setState(() => _radialGauge = false),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: IoTTheme.primaryBlue,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(isEditing ? 'Save Changes' : 'Add Widget'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(MetricVisualType type) {
    switch (type) {
      case MetricVisualType.standard:
        return 'Value card';
      case MetricVisualType.gauge:
        return 'Gauge';
      case MetricVisualType.chart:
        return 'Live chart';
    }
  }
}

const List<IconData> _iconChoices = [
  Icons.favorite,
  Icons.monitor_heart,
  Icons.thermostat,
  Icons.air,
  Icons.directions_walk,
  Icons.local_fire_department,
  Icons.speed,
  Icons.show_chart,
  Icons.water_drop,
  Icons.fitness_center,
];

const List<Color> _colorChoices = [
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.cyan,
  Colors.pink,
  Colors.indigo,
  Colors.amber,
];
