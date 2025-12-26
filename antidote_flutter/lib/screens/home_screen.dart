import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../widgets/shooting_stars.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _backgroundController;
  final TextEditingController _urlController = TextEditingController();
  final List<ShootingStar> _shootingStars = [];
  late Timer _starTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // Background zoom controller
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    
    _generateShootingStars();
    _starTimer = Timer.periodic(const Duration(seconds: 8), (_) => _generateShootingStars());
  }
  
  void _generateShootingStars() {
    setState(() {
      _shootingStars.clear();
      final colors = [ShootingStarColor.purple, ShootingStarColor.cyan, ShootingStarColor.pink];
      final random = Random();
      
      for (int i = 0; i < 3; i++) {
        _shootingStars.add(ShootingStar(
          delay: random.nextDouble() * 5,
          color: colors[random.nextInt(colors.length)],
          startPosition: Offset(
            random.nextDouble() * 300 + 50,
            random.nextDouble() * 200,
          ),
        ));
      }
    });
  }
  
  @override
  void dispose() {
    _logoController.dispose();
    _backgroundController.dispose();
    _urlController.dispose();
    _starTimer.cancel();
    super.dispose();
  }

  void _handleAnalyze() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      context.go('/analysis?url=${Uri.encodeComponent(url)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated Cosmic Background
        AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                  opacity: 0.6,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.background.withValues(alpha: 0.2),
                      AppTheme.background,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Shooting Stars
        ..._shootingStars.map((star) => ShootingStarsWidget(star: star)),
        
        // Main Content
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60), // Status bar spacing
                
                // Hero Section
                SizedBox(
                  height: 420,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              sin(_logoController.value * 2 * pi) * 10,
                            ),
                            child: Transform.rotate(
                              angle: sin(_logoController.value * 2 * pi) * 0.1,
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(alpha: 0.6),
                                      blurRadius: 20,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.music_note,
                                      size: 48,
                                      color: AppTheme.primary,
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Animated Title
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          final shadowOffset = sin(_logoController.value * 2 * pi) * 2 + 2;
                          return Text(
                            'ANTIDOTE',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              shadows: [
                                Shadow(
                                  color: AppTheme.primary.withValues(alpha: 1),
                                  offset: Offset(0, shadowOffset),
                                  blurRadius: shadowOffset * 2,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: (sin(_logoController.value * 2 * pi) + 1) / 2 * 0.3 + 0.7,
                            child: Text(
                              'Discover the DNA of your music taste.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textMuted,
                                fontFamily: 'Space Mono',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Input Section
                Transform.translate(
                  offset: const Offset(0, -48),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground.withValues(alpha: 0.5),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // URL Input
                        Row(
                          children: [
                            Text(
                              'Playlist URL',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            hintText: 'Paste Spotify or Apple Music link...',
                            hintStyle: TextStyle(
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppTheme.textMuted,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.secondary.withValues(alpha: 0.5),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.4),
                          ),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontFamily: 'Space Mono',
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Analyze Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _handleAnalyze,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: AppTheme.accent.withValues(alpha: 0.3),
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'REVEAL MY DESTINY',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Feature Cards
                Text(
                  'Modules',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildFeatureCard(
                      context,
                      icon: Icons.favorite,
                      title: 'Health Check',
                      description: 'Analyze playlist consistency & flow',
                      route: '/analysis',
                      color: AppTheme.success,
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.bolt,
                      title: 'Battle Mode',
                      description: 'Compare two playlists head-to-head',
                      route: '/battle',
                      color: AppTheme.accent,
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.auto_fix_high,
                      title: 'Decision Assistant',
                      description: 'AI picks your next perfect track',
                      route: '/music-assistant',
                      color: AppTheme.secondary,
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.share,
                      title: 'Share & Save',
                      description: 'Save & share your analysis results',
                      route: '/profile',
                      color: AppTheme.primary,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Discover More Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.withValues(alpha: 0.2),
                        AppTheme.primary.withValues(alpha: 0.2),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover More',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Get songs that actually fit the vibe',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 120), // Bottom spacing
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String route,
    required Color color,
  }) {
    return InkWell(
      onTap: () => context.go(route),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
