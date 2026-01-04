import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';

class RecommendationStrategy {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  RecommendationStrategy({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class MusicAssistantScreen extends StatefulWidget {
  const MusicAssistantScreen({super.key});

  @override
  State<MusicAssistantScreen> createState() => _MusicAssistantScreenState();
}

class _MusicAssistantScreenState extends State<MusicAssistantScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  final List<AnimationController> _cardControllers = [];

  final List<RecommendationStrategy> _strategies = [
    RecommendationStrategy(
      id: 'best_next',
      title: 'Best Next Track',
      description: 'AI picks perfect next song',
      icon: Icons.lightbulb,
      color: AppTheme.warning,
    ),
    RecommendationStrategy(
      id: 'mood_safe',
      title: 'Mood-Safe Pick',
      description: 'Maintains current vibe',
      icon: Icons.favorite,
      color: Colors.redAccent,
    ),
    RecommendationStrategy(
      id: 'rare_match',
      title: 'Rare Match For You',
      description: 'Hidden gems matching taste',
      icon: Icons.explore,
      color: AppTheme.secondary,
    ),
    RecommendationStrategy(
      id: 'return_familiar',
      title: 'Return To Familiar',
      description: 'Deep cuts from loved artists',
      icon: Icons.refresh,
      color: AppTheme.primary,
    ),
    RecommendationStrategy(
      id: 'short_session',
      title: 'Short Session Mode',
      description: 'Perfect 5-10 minute tracks',
      icon: Icons.music_note,
      color: AppTheme.success,
    ),
    RecommendationStrategy(
      id: 'energy_adjust',
      title: 'Energy Adjustment',
      description: 'Shift energy up or down',
      icon: Icons.bolt,
      color: AppTheme.accent,
    ),
    RecommendationStrategy(
      id: 'professional_discovery',
      title: 'Professional Discovery',
      description: 'Multi-source AI analysis',
      icon: Icons.auto_awesome,
      color: Colors.purple,
    ),
    RecommendationStrategy(
      id: 'taste_expansion',
      title: 'Taste Expansion',
      description: 'Bridge to new genres',
      icon: Icons.explore_outlined,
      color: Colors.teal,
    ),
    RecommendationStrategy(
      id: 'deep_cuts',
      title: 'Deep Cuts',
      description: 'Hidden gems from favorites',
      icon: Icons.diamond,
      color: Colors.cyan,
    ),
    RecommendationStrategy(
      id: 'continue_session',
      title: 'Continue Session',
      description: 'Based on recent listening',
      icon: Icons.play_circle,
      color: Colors.orange,
    ),
    RecommendationStrategy(
      id: 'from_library',
      title: 'From Your Library',
      description: 'Deep cuts from saved tracks',
      icon: Icons.library_music,
      color: Colors.indigo,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize card controllers
    for (int i = 0; i < _strategies.length; i++) {
      _cardControllers.add(AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ));
    }

    // Start staggered animation
    _staggerController.forward().then((_) {
      for (int i = 0; i < _cardControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 100), () {
          if (mounted) _cardControllers[i].forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom +
            80, // Bottom nav + safe area
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/'),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.textMuted,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Music Decision Assistant',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Auth Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: AppTheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRO TIP',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign up to unlock personalized flavor profiles and smarter recommendations across all playlists.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Strategy Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: _strategies.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _cardControllers[index],
                  builder: (context, child) {
                    final scale = 0.8 + (0.2 * _cardControllers[index].value);
                    final opacity = _cardControllers[index].value;

                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: _buildStrategyCard(
                          context,
                          _strategies[index],
                          index,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // CTA Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to auth
                      context.go('/auth');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Sign Up for More'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      // Continue as guest
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Continuing as guest with limited features'),
                          backgroundColor: AppTheme.cardBackground,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue as Guest',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(
    BuildContext context,
    RecommendationStrategy strategy,
    int index,
  ) {
    return InkWell(
      onTap: () {
        // Navigate to recommendations screen
        context.go(
          '/recommendations?strategyId=${Uri.encodeComponent(strategy.id)}&strategyTitle=${Uri.encodeComponent(strategy.title)}&strategyColor=${strategy.color.toARGB32()}',
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withValues(alpha: 0.3),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: strategy.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                strategy.icon,
                color: strategy.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strategy.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              strategy.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
