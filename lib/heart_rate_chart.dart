import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iot/theme/iot_theme.dart';

class HeartRateChart extends StatefulWidget {
  final String dataSource; // e.g. "heartrate"
  final Color lineColor;
  final String title;
  final String unit;
  final VoidCallback? onRemove;
  final String? heartRateValue; // Current Heart Rate value from Firebase
  final String? heartRateTimestamp; // Timestamp of Heart Rate update

  const HeartRateChart({
    Key? key,
    required this.dataSource,
    this.lineColor = Colors.red,
    this.title = "Heart Rate",
    this.unit = "BPM",
    this.onRemove,
    this.heartRateValue,
    this.heartRateTimestamp,
  }) : super(key: key);

  @override
  State<HeartRateChart> createState() => _HeartRateChartState();
}

class _HeartRateChartState extends State<HeartRateChart> {
  final List<FlSpot> _spots = [];
  final int _maxPoints = 50;
  double? _lastValue;

  @override
  void didUpdateWidget(HeartRateChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.heartRateValue != null && 
        widget.heartRateValue != _lastValue?.toString()) {
      
      final value = double.tryParse(widget.heartRateValue ?? '0') ?? 0.0;
      
      final xIndex = _spots.length.toDouble();
      
      setState(() {
        _spots.add(FlSpot(xIndex, value));
        
        if (_spots.length > _maxPoints) {
          _spots.removeAt(0);
          for (int i = 0; i < _spots.length; i++) {
            _spots[i] = FlSpot(i.toDouble(), _spots[i].y);
          }
        }
        
        _lastValue = value;
      });
    }
  }

  String _formatX(double index) {
    return index.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _spots.isNotEmpty;

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
                        color: widget.lineColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.show_chart,
                        color: widget.lineColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.title,
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
              if (widget.onRemove != null)
                InkWell(
                  onTap: widget.onRemove,
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
          SizedBox(
            height: 200,
            child: hasData
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 10,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: hasData && _spots.length > 10 ? (_spots.length / 5).ceilToDouble() : 1,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _formatX(value),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: hasData ? _spots.last.x : 10,
                      minY: hasData
                          ? _spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 10
                          : 0,
                      maxY: hasData
                          ? _spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 10
                          : 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: widget.lineColor,
                          barWidth: 3.5,
                          dotData: FlDotData(
                            show: false,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: widget.lineColor,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                widget.lineColor.withOpacity(0.3),
                                widget.lineColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                          shadow: Shadow(
                            color: widget.lineColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 48,
                          color: widget.lineColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Waiting for data...",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.lineColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.lineColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.lineColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.lineColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  hasData
                      ? '${_spots.last.y.toStringAsFixed(0)} ${widget.unit}'
                      : (widget.heartRateValue != null 
                          ? '${widget.heartRateValue} ${widget.unit}'
                          : '- ${widget.unit}'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.lineColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
