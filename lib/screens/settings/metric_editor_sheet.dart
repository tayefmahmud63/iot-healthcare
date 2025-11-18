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

class _MetricEditorSheetState extends State<MetricEditorSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _firebaseFieldController;
  late final TextEditingController _unitController;
  late MetricVisualType _selectedType;
  late bool _radialGauge;
  late IconData _selectedIcon;
  late Color _selectedColor;
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firebaseFieldController.dispose();
    _unitController.dispose();
    _animationController.dispose();
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
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final maxHeight = screenHeight - topPadding - (bottomInset > 0 ? bottomInset : bottomPadding);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: true,
        left: true,
        right: true,
        bottom: true,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 
                ? bottomInset 
                : 0,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: IoTTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: IoTTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_rounded : Icons.add_rounded,
                          color: IoTTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Widget' : 'Create Widget',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEditing
                                  ? 'Update widget settings'
                                  : 'Add a new metric widget',
                              style: TextStyle(
                                fontSize: 13,
                                color: IoTTheme.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: IoTTheme.borderColor.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information Section
                          _SectionHeader(
                            title: 'Basic Information',
                            icon: Icons.info_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _ModernTextField(
                            controller: _nameController,
                            label: 'Widget Name',
                            hint: 'e.g., Heart Rate',
                            icon: Icons.label_outline_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _ModernTextField(
                            controller: _firebaseFieldController,
                            label: 'Firebase field (inside metrics..)',
                            hint: 'Exactly as stored in Firebase',
                            icon: Icons.key_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Firebase field is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Widget Type Section
                          _SectionHeader(
                            title: 'Widget Type',
                            icon: Icons.dashboard_outlined,
                          ),
                          const SizedBox(height: 16),
                          _TypeSelector(
                            selectedType: _selectedType,
                            onTypeChanged: lockVisualType
                                ? null
                                : (type) {
                                    setState(() => _selectedType = type);
                                  },
                          ),
                          if (_selectedType != MetricVisualType.button &&
                              _selectedType != MetricVisualType.pushButton) ...[
                            const SizedBox(height: 16),
                            _ModernTextField(
                              controller: _unitController,
                              label: _selectedType == MetricVisualType.gauge
                                  ? 'Label / Unit'
                                  : 'Unit',
                              hint: _selectedType == MetricVisualType.gauge
                                  ? '°C, PSI, %, etc.'
                                  : 'e.g., %',
                              icon: Icons.straighten_rounded,
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
                          ],
                          if (_selectedType == MetricVisualType.gauge) ...[
                            const SizedBox(height: 16),
                            _GaugeTypeSelector(
                              isRadial: _radialGauge,
                              onChanged: (value) =>
                                  setState(() => _radialGauge = value),
                            ),
                          ],
                          const SizedBox(height: 24),
                          // Styling Section
                          _SectionHeader(
                            title: 'Styling',
                            icon: Icons.palette_outlined,
                          ),
                          const SizedBox(height: 16),
                          _IconSelector(
                            selectedIcon: _selectedIcon,
                            onIconSelected: (icon) =>
                                setState(() => _selectedIcon = icon),
                          ),
                          const SizedBox(height: 16),
                          _ColorSelector(
                            selectedColor: _selectedColor,
                            onColorSelected: (color) =>
                                setState(() => _selectedColor = color),
                          ),
                          const SizedBox(height: 32),
                          // Save Button
                          _ModernButton(
                            onPressed: _isSaving ? null : _handleSave,
                            isLoading: _isSaving,
                            label: isEditing ? 'Save Changes' : 'Create Widget',
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: IoTTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: IoTTheme.darkBackground,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: IoTTheme.textSecondary),
        filled: true,
        fillColor: IoTTheme.lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: IoTTheme.borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: IoTTheme.borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: IoTTheme.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: IoTTheme.accentPink, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: IoTTheme.accentPink, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: IoTTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final MetricVisualType selectedType;
  final ValueChanged<MetricVisualType>? onTypeChanged;

  const _TypeSelector({
    required this.selectedType,
    this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = MetricVisualType.values;
    return Column(
      children: [
        Row(
          children: types.take(3).map((type) {
            final isSelected = type == selectedType;
            final isDisabled = onTypeChanged == null;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != types.take(3).last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: isDisabled ? null : () => onTypeChanged?.call(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? IoTTheme.primaryBlue.withOpacity(0.1)
                          : IoTTheme.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? IoTTheme.primaryBlue
                            : IoTTheme.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(type),
                          size: 22,
                          color: isSelected
                              ? IoTTheme.primaryBlue
                              : IoTTheme.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getTypeLabel(type),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? IoTTheme.primaryBlue
                                : IoTTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (types.length > 3) ...[
          const SizedBox(height: 8),
          Row(
            children: types.skip(3).map((type) {
              final isSelected = type == selectedType;
              final isDisabled = onTypeChanged == null;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type != types.skip(3).last ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: isDisabled ? null : () => onTypeChanged?.call(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? IoTTheme.primaryBlue.withOpacity(0.1)
                            : IoTTheme.lightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? IoTTheme.primaryBlue
                              : IoTTheme.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(type),
                            size: 22,
                            color: isSelected
                                ? IoTTheme.primaryBlue
                                : IoTTheme.textSecondary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getTypeLabel(type),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? IoTTheme.primaryBlue
                                  : IoTTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  IconData _getTypeIcon(MetricVisualType type) {
    switch (type) {
      case MetricVisualType.standard:
        return Icons.dashboard_rounded;
      case MetricVisualType.gauge:
        return Icons.speed_rounded;
      case MetricVisualType.chart:
        return Icons.show_chart_rounded;
      case MetricVisualType.button:
        return Icons.toggle_on_rounded;
      case MetricVisualType.pushButton:
        return Icons.touch_app_rounded;
    }
  }

  String _getTypeLabel(MetricVisualType type) {
    switch (type) {
      case MetricVisualType.standard:
        return 'Card';
      case MetricVisualType.gauge:
        return 'Gauge';
      case MetricVisualType.chart:
        return 'Chart';
      case MetricVisualType.button:
        return 'Button';
      case MetricVisualType.pushButton:
        return 'Push';
    }
  }
}

class _GaugeTypeSelector extends StatelessWidget {
  final bool isRadial;
  final ValueChanged<bool> onChanged;

  const _GaugeTypeSelector({
    required this.isRadial,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: IoTTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IoTTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _GaugeTypeOption(
              label: 'Radial',
              icon: Icons.radio_button_checked_rounded,
              isSelected: isRadial,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _GaugeTypeOption(
              label: 'Linear',
              icon: Icons.remove_rounded,
              isSelected: !isRadial,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugeTypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GaugeTypeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? IoTTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : IoTTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : IoTTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconSelector extends StatelessWidget {
  final IconData selectedIcon;
  final ValueChanged<IconData> onIconSelected;

  const _IconSelector({
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _iconChoices.map((iconData) {
        final isSelected = iconData == selectedIcon;
        return GestureDetector(
          onTap: () => onIconSelected(iconData),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? IoTTheme.primaryBlue.withOpacity(0.15)
                  : IoTTheme.lightBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? IoTTheme.primaryBlue
                    : IoTTheme.borderColor,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Icon(
              iconData,
              color: isSelected
                  ? IoTTheme.primaryBlue
                  : IoTTheme.textSecondary,
              size: 24,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorSelector extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorSelector({
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colorChoices.map((color) {
        final isSelected = color.value == selectedColor.value;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: isSelected
                ? const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _ModernButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _ModernButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: IoTTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
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
