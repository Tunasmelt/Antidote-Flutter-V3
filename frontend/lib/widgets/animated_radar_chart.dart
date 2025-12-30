import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme.dart';

class RadarData {
  final String label;
  final double value;
  
  RadarData({required this.label, required this.value});
}

class AnimatedRadarChart extends StatefulWidget {
  final List<RadarData> data;
  final Color? color;
  final Color? fillColor;
  
  const AnimatedRadarChart({
    super.key,
    required this.data,
    this.color,
    this.fillColor,
  });
  
  @override
  State<AnimatedRadarChart> createState() => _AnimatedRadarChartState();
}

class _AnimatedRadarChartState extends State<AnimatedRadarChart> 
    with SingleTickerProviderStateMixin {
      
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primary;
    final fillColor = widget.fillColor ?? color.withValues(alpha: 0.1);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return RadarChart(
          RadarChartData(
            dataSets: [
              RadarDataSet(
                dataEntries: widget.data.map((d) => 
                  RadarEntry(value: d.value * _animation.value)
                ).toList(),
                borderColor: color,
                fillColor: fillColor,
                borderWidth: 3,
                entryRadius: 0,
              ),
            ],
            radarShape: RadarShape.polygon,
            radarBorderData: const BorderSide(
              color: Colors.transparent,
            ),
            gridBorderData: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            tickBorderData: const BorderSide(
              color: Colors.transparent,
            ),
            ticksTextStyle: const TextStyle(
              color: Colors.transparent,
            ),
            titleTextStyle: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontFamily: 'Space Mono',
            ),
            getTitle: (index, angle) {
              return RadarChartTitle(
                text: widget.data[index].label,
                angle: angle,
              );
            },
          ),
        );
      },
    );
  }
}

class DualRadarChart extends StatefulWidget {
  final List<RadarData> playlist1Data;
  final List<RadarData> playlist2Data;
  
  const DualRadarChart({
    super.key, 
    required this.playlist1Data, 
    required this.playlist2Data,
  });
  
  @override
  State<DualRadarChart> createState() => _DualRadarChartState();
}

class _DualRadarChartState extends State<DualRadarChart> 
    with SingleTickerProviderStateMixin {
      
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return RadarChart(
          RadarChartData(
            dataSets: [
              // Playlist 1
              RadarDataSet(
                dataEntries: widget.playlist1Data.map((d) => 
                  RadarEntry(value: d.value * _animation.value)
                ).toList(),
                borderColor: AppTheme.secondary,
                fillColor: AppTheme.secondary.withValues(alpha: 0.1),
                borderWidth: 2,
                entryRadius: 0,
              ),
              // Playlist 2
              RadarDataSet(
                dataEntries: widget.playlist2Data.map((d) => 
                  RadarEntry(value: d.value * _animation.value)
                ).toList(),
                borderColor: AppTheme.accent,
                fillColor: AppTheme.accent.withValues(alpha: 0.1),
                borderWidth: 2,
                entryRadius: 0,
              ),
            ],
            radarShape: RadarShape.polygon,
            radarBorderData: const BorderSide(
              color: Colors.transparent,
            ),
            gridBorderData: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            tickBorderData: const BorderSide(
              color: Colors.transparent,
            ),
            ticksTextStyle: const TextStyle(
              color: Colors.transparent,
            ),
            titleTextStyle: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontFamily: 'Space Mono',
            ),
            getTitle: (index, angle) => RadarChartTitle(
              text: widget.playlist1Data[index].label,
              angle: angle,
            ),
          ),
        );
      },
    );
  }
}

