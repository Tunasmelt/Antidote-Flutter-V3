import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../services/api_client.dart';
import '../providers/api_client_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<AnimationController> _itemControllers = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var itemController in _itemControllers) {
      itemController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ref.watch(apiClientProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchHistory(apiClient),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading History...',
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load history',
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }

          final historyItems = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      TextButton.icon(
                        onPressed: () => context.go('/profile'),
                        icon: Icon(Icons.arrow_back, size: 16, color: AppTheme.mutedColor),
                        label: Text(
                          'Back to Profile',
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedColor,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(left: 0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      FadeTransition(
                        opacity: _controller,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _controller,
                            curve: Curves.easeOut,
                          )),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'History',
                                style: AppTheme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'PressStart2P',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your recent analyses and battles',
                                style: AppTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mutedColor,
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: historyItems.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              'No history yet.',
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mutedColor,
                              ),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = historyItems[index];
                            final isBattle = item['type'] == 'battle';
                            
                            // Create animation controller for this item
                            if (index >= _itemControllers.length) {
                              final controller = AnimationController(
                                vsync: this,
                                duration: const Duration(milliseconds: 300),
                              );
                              _itemControllers.add(controller);
                              Future.delayed(
                                Duration(milliseconds: 100 + (index * 80)),
                                () => controller.forward(),
                              );
                            }
                            
                            final itemController = _itemControllers[index];
                            
                            return FadeTransition(
                              opacity: itemController,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: itemController,
                                  curve: Curves.easeOut,
                                )),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildHistoryItem(item, isBattle),
                                ),
                              ),
                            );
                          },
                          childCount: historyItems.length,
                        ),
                      ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, bool isBattle) {
    final bgColor = isBattle
        ? Colors.pink.withValues(alpha: 0.1)
        : Colors.cyan.withValues(alpha: 0.1);
    final iconColor = isBattle ? Colors.pink : Colors.cyan;
    final icon = isBattle ? Icons.sports_martial_arts : Icons.music_note;
    
    final date = item['date'] != null
        ? DateTime.parse(item['date'])
        : DateTime.now();
    final timeAgo = _formatTimeAgo(date);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.3),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to analysis/battle detail
            if (isBattle) {
              // Navigate to battle screen (could pass battle ID if available)
              context.go('/battle');
            } else {
              // Navigate to analysis screen with URL if available
              final url = item['url'] as String?;
              if (url != null) {
                context.go('/analysis?url=${Uri.encodeComponent(url)}');
              } else {
                // Fallback: just go to analysis screen
                context.go('/analysis');
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? 'Untitled',
                        style: AppTheme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppTheme.mutedColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedColor,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isBattle
                                  ? Colors.pink.withValues(alpha: 0.2)
                                  : Colors.cyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['type']?.toString().toUpperCase() ?? 'UNKNOWN',
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: isBattle
                                    ? Colors.pink.shade300
                                    : Colors.cyan.shade300,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchHistory(ApiClient apiClient) async {
    try {
      return await apiClient.getHistory();
    } catch (e) {
      throw Exception('Failed to fetch history: $e');
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

