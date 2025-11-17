import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:iot/theme/iot_theme.dart';

class GaugeWidget extends StatelessWidget {
  final double temperature;
  final bool isRadialGauge;
  final VoidCallback? onRemove;

  GaugeWidget({Key? key, required this.temperature, required this.isRadialGauge, this.onRemove}) : super(key: key);

  Widget _getGauge() {
    if (isRadialGauge) {
      return _getRadialGauge();
    } else {
      return _getLinearGauge();
    }
  }

  Widget _getRadialGauge() {
    return SfRadialGauge(
      title: GaugeTitle(
        text: 'Temperature',
        textStyle: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: IoTTheme.textSecondary,
        ),
      ),
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 100,
          startAngle: 180,
          endAngle: 0,
          axisLineStyle: AxisLineStyle(
            thickness: 0.15,
            thicknessUnit: GaugeSizeUnit.factor,
            color: IoTTheme.darkSurface,
          ),
          ranges: <GaugeRange>[
            GaugeRange(
              startValue: 0,
              endValue: 50,
              color: IoTTheme.primaryBlue,
              startWidth: 0.15,
              endWidth: 0.15,
            ),
            GaugeRange(
              startValue: 50,
              endValue: 75,
              color: IoTTheme.primaryPurple,
              startWidth: 0.15,
              endWidth: 0.15,
            ),
            GaugeRange(
              startValue: 75,
              endValue: 100,
              color: IoTTheme.accentPink,
              startWidth: 0.15,
              endWidth: 0.15,
            ),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(
              value: temperature,
              enableAnimation: true,
              animationType: AnimationType.easeOutBack,
              animationDuration: 1500,
              needleColor: IoTTheme.primaryBlue,
              needleStartWidth: 1,
              needleEndWidth: 4,
              knobStyle: KnobStyle(
                knobRadius: 0.08,
                color: IoTTheme.primaryBlue,
                borderColor: Colors.white,
                borderWidth: 0.05,
              ),
              tailStyle: TailStyle(
                color: IoTTheme.primaryBlue.withOpacity(0.5),
                width: 4,
                length: 0.2,
              ),
            )
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      temperature.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: IoTTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      '°C',
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
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SfLinearGauge(
          minimum: 0.0,
          maximum: 100.0,
          orientation: LinearGaugeOrientation.horizontal,
          majorTickStyle: const LinearTickStyle(length: 20),
          axisLabelStyle: const TextStyle(fontSize: 12.0, color: Colors.black),
          axisTrackStyle: LinearAxisTrackStyle(
            color: Colors.cyan,
            edgeStyle: LinearEdgeStyle.bothFlat,
            thickness: 15.0,
            borderColor: Colors.grey,
          ),
          markerPointers: [
            LinearShapePointer(
              value: temperature,
              color: Colors.blue,
            ),
          ],
        ),
      ),
      margin: const EdgeInsets.all(10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: IoTTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.speed,
                        color: IoTTheme.primaryBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isRadialGauge ? 'Temperature Gauge' : 'Linear Gauge',
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
