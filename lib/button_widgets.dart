import 'package:flutter/material.dart';
import 'package:iot/services/firebase_database_service.dart';
import 'package:iot/theme/iot_theme.dart';

class ToggleButtonWidget extends StatefulWidget {
  final String title;
  final String firebaseField;
  final IconData icon;
  final Color accentColor;
  final FirebaseDatabaseService firebaseService;

  const ToggleButtonWidget({
    Key? key,
    required this.title,
    required this.firebaseField,
    required this.icon,
    required this.accentColor,
    required this.firebaseService,
  }) : super(key: key);

  @override
  State<ToggleButtonWidget> createState() => _ToggleButtonWidgetState();
}

class _ToggleButtonWidgetState extends State<ToggleButtonWidget> {
  bool? _currentValue;

  @override
  void initState() {
    super.initState();
    _loadCurrentValue();
    _watchValue();
  }

  Future<void> _loadCurrentValue() async {
    try {
      final data = await widget.firebaseService.readData('metrics/${widget.firebaseField}');
      if (data != null) {
        final value = data['value'];
        setState(() {
          _currentValue = value is bool ? value : (value == 'true' || value == true);
        });
      } else {
        setState(() {
          _currentValue = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentValue = false;
      });
    }
  }

  void _watchValue() {
    widget.firebaseService.watchData('metrics/${widget.firebaseField}').listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value;
        if (data is Map) {
          final value = data['value'];
          setState(() {
            _currentValue = value is bool ? value : (value == 'true' || value == true);
          });
        }
      }
    });
  }

  Future<void> _toggleValue() async {
    final newValue = !(_currentValue ?? false);
    
    setState(() {
      _currentValue = newValue;
    });
    
    try {
      await widget.firebaseService.writeData(
        'metrics/${widget.firebaseField}',
        {
          'value': newValue,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _currentValue = !newValue;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _currentValue ?? false;

    return GestureDetector(
      onTap: _toggleValue,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: isActive ? widget.accentColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? widget.accentColor : IoTTheme.borderColor,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ]
              : IoTTheme.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.2)
                    : widget.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                size: 24,
                color: isActive ? Colors.white : widget.accentColor,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : IoTTheme.darkBackground,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? Colors.white.withOpacity(0.9)
                        : IoTTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.3)
                    : IoTTheme.borderColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    left: isActive ? 26 : 2,
                    top: 2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PushButtonWidget extends StatefulWidget {
  final String title;
  final String firebaseField;
  final IconData icon;
  final Color accentColor;
  final FirebaseDatabaseService firebaseService;

  const PushButtonWidget({
    Key? key,
    required this.title,
    required this.firebaseField,
    required this.icon,
    required this.accentColor,
    required this.firebaseService,
  }) : super(key: key);

  @override
  State<PushButtonWidget> createState() => _PushButtonWidgetState();
}

class _PushButtonWidgetState extends State<PushButtonWidget> {
  bool _isPressed = false;

  Future<void> _setValue(bool value) async {
    try {
      await widget.firebaseService.writeData(
        'metrics/${widget.firebaseField}',
        {
          'value': value,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _setValue(true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _setValue(false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _setValue(false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: _isPressed ? widget.accentColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isPressed ? widget.accentColor : IoTTheme.borderColor,
            width: 1.5,
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ]
              : IoTTheme.cardShadow,
        ),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isPressed
                    ? Colors.white.withOpacity(0.2)
                    : widget.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                size: 24,
                color: _isPressed ? Colors.white : widget.accentColor,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _isPressed ? Colors.white : IoTTheme.darkBackground,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPressed ? 'Active' : 'Press & Hold',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isPressed
                        ? Colors.white.withOpacity(0.9)
                        : IoTTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isPressed
                    ? Colors.white.withOpacity(0.25)
                    : widget.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPressed ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
                color: _isPressed ? Colors.white : widget.accentColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

