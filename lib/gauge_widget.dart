import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:iot/theme/iot_theme.dart';

class GaugeWidget extends StatelessWidget {
  final double value;
  final bool isRadialGauge;
  final String title;
  final String unit;
  final double minValue;
  final double maxValue;
  final Color accentColor;
  final VoidCallback? onRemove;

  const GaugeWidget({
    Key? key,
    required this.value,
    required this.isRadialGauge,
    required this.title,
    required this.unit,
    this.minValue = 0,
    this.maxValue = 100,
    this.accentColor = const Color(0xFF1E88E5),
    this.onRemove,
  }) : super(key: key);

  Widget _getGauge() {
    if (isRadialGauge) {
      return _getRadialGauge();
    } else {
      return _getLinearGauge();
    }
  }

  double get _clampedValue {
    if (value < minValue) return minValue;
    if (value > maxValue) return maxValue;
    return value;
  }

  double get _range =>
      (maxValue - minValue).abs() < 0.0001 ? 1 : (maxValue - minValue);
  double get _segment => _range / 3;

  Widget _getRadialGauge() {
    return SfRadialGauge(
      title: GaugeTitle(
        text: title,
        textStyle: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: IoTTheme.textSecondary,
        ),
      ),
      axes: <RadialAxis>[
        RadialAxis(
          minimum: minValue,
          maximum: maxValue,
          startAngle: 180,
          endAngle: 0,
          axisLineStyle: AxisLineStyle(
            thickness: 0.15,
            thicknessUnit: GaugeSizeUnit.factor,
            color: IoTTheme.darkSurface,
          ),
          ranges: <GaugeRange>[
            GaugeRange(
              startValue: minValue,
              endValue: minValue + _segment,
              color: accentColor.withOpacity(0.4),
              startWidth: 0.15,
              endWidth: 0.15,
            ),
            GaugeRange(
              startValue: minValue + _segment,
              endValue: minValue + 2 * _segment,
              color: IoTTheme.primaryPurple,
              startWidth: 0.15,
              endWidth: 0.15,
            ),
            GaugeRange(
              startValue: minValue + 2 * _segment,
              endValue: maxValue,
              color: IoTTheme.accentPink,
              startWidth: 0.15,
              endWidth: 0.15,
            ),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(
              value: _clampedValue,
              enableAnimation: true,
              animationType: AnimationType.easeOutBack,
              animationDuration: 1500,
              needleColor: accentColor,
              needleStartWidth: 1,
              needleEndWidth: 4,
              knobStyle: KnobStyle(
                knobRadius: 0.08,
                color: accentColor,
                borderColor: Colors.white,
                borderWidth: 0.05,
              ),
              tailStyle: TailStyle(
                color: accentColor.withOpacity(0.5),
                width: 4,
                length: 0.2,
              ),
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: IoTTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              angle: 90,
              positionFactor: 0.5,
            ),
          ],
        ),
      ],
    );
  }

  Widget _getLinearGauge() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SfLinearGauge(
        minimum: minValue,
        maximum: maxValue,
        orientation: LinearGaugeOrientation.horizontal,
        majorTickStyle: const LinearTickStyle(length: 20),
        axisLabelStyle: const TextStyle(fontSize: 12.0, color: Colors.black),
        axisTrackStyle: LinearAxisTrackStyle(
          color: accentColor.withOpacity(0.2),
          edgeStyle: LinearEdgeStyle.bothFlat,
          thickness: 15.0,
          borderColor: accentColor.withOpacity(0.4),
        ),
        markerPointers: [
          LinearShapePointer(value: _clampedValue, color: accentColor),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IoTTheme.borderColor, width: 1),
        boxShadow: IoTTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.speed, color: accentColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: IoTTheme.darkBackground,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: IoTTheme.accentPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: IoTTheme.accentPink,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _getGauge(),
        ],
      ),
    );
  }
}
