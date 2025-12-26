import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/analysis.dart';

class GenreDistributionBars extends StatefulWidget {
  final List<GenreDistribution> genres;
  
  const GenreDistributionBars({
    super.key,
    required this.genres,
  });
  
  @override
  State<GenreDistributionBars> createState() => _GenreDistributionBarsState();
}

class _GenreDistributionBarsState extends State<GenreDistributionBars> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.genres.asMap().entries.map((entry) {
        final index = entry.key;
        final genre = entry.value;
        
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.1;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);
            final animatedValue = Curves.easeOut.transform(progress);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          genre.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${genre.value}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontFamily: 'Space Mono',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      value: (genre.value / 100) * animatedValue,
                      backgroundColor: Colors.black.withValues(alpha: 0.4),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

