import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';

class MobileLayout extends StatelessWidget {
  final Widget child;
  final bool showBottomNavigation;

  const MobileLayout({
    super.key,
    required this.child,
    this.showBottomNavigation = true,
  });

  @override
  Widget build(BuildContext context) {
    // Get safe area insets
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false, // We'll handle bottom padding manually for navigation
        child: Column(
          children: [
            // Content area - takes remaining space
            Expanded(
              child: child,
            ),
            // Bottom Navigation Bar
            if (showBottomNavigation) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: _buildBottomNavigation(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomNavigation(BuildContext context) {
    final router = GoRouter.of(context);
    final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
    
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(context, Icons.home, 'Home', '/', currentLocation),
          _buildTabItem(context, Icons.bar_chart, 'Analysis', '/analysis', currentLocation),
          _buildTabItem(context, Icons.sports_mma, 'Battle', '/battle', currentLocation),
          _buildTabItem(context, Icons.person, 'Profile', '/profile', currentLocation),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, IconData icon, String label, String route, String currentLocation) {
    final isActive = currentLocation == route || (route == '/' && currentLocation == '/');
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          child: SizedBox(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppTheme.primary : AppTheme.textMuted,
                  size: isActive ? 26 : 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? AppTheme.primary : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.5,
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
