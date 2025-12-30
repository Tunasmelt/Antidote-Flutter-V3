import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';

class MobileLayout extends StatelessWidget {
  final Widget child;
  final bool showFrame;

  const MobileLayout({
    super.key,
    required this.child,
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showFrame) {
      return Scaffold(
        body: child,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 400,
          height: 850,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.grey.shade800,
              width: 8,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Scaffold(
              body: Stack(
                children: [
                  // Content
                  Positioned.fill(
                    top: 44, // Status bar height
                    bottom: 80, // Tab bar height
                    child: child,
                  ),
                  
                  // Status Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 44,
                    child: Container(
                      color: AppTheme.cardBackground.withValues(alpha: 0.8),
                      child: Row(
                        children: [
                          const SizedBox(width: 24),
                          Text(
                            '9:41',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                              fontFamily: 'Space Mono',
                            ),
                          ),
                          const Spacer(),
                          // Signal indicators
                          Row(
                            children: List.generate(
                              4,
                              (index) => Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                        ],
                      ),
                    ),
                  ),
                  
                  // Tab Bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      color: AppTheme.cardBackground.withValues(alpha: 0.8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTabItem(context, Icons.home, 'Home', '/'),
                          _buildTabItem(context, Icons.bar_chart, 'Analysis', '/analysis'),
                          _buildTabItem(context, Icons.sports_mma, 'Battle', '/battle'),
                          _buildTabItem(context, Icons.person, 'Profile', '/profile'),
                        ],
                      ),
                    ),
                  ),
                  
                  // Home Indicator
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    height: 4,
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, IconData icon, String label, String route) {
    final router = GoRouter.of(context);
    final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
    final isActive = currentLocation == route || (route == '/' && currentLocation == '/');
    
    return InkWell(
      onTap: () => context.go(route),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.textMuted,
              size: isActive ? 24 : 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
