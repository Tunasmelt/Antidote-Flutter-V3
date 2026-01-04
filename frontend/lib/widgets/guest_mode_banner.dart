import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../services/guest_storage_service.dart';

/// A banner that shows in guest mode to remind users to sign up
/// Shows countdown of remaining days until guest data expires
class GuestModeBanner extends StatefulWidget {
  const GuestModeBanner({super.key});

  @override
  State<GuestModeBanner> createState() => _GuestModeBannerState();
}

class _GuestModeBannerState extends State<GuestModeBanner> {
  int _daysRemaining = 7;

  @override
  void initState() {
    super.initState();
    _calculateDaysRemaining();
  }

  Future<void> _calculateDaysRemaining() async {
    try {
      // Check if there's any guest data
      final hasGuestData = await GuestStorageService.hasGuestData();

      if (hasGuestData && mounted) {
        // Calculate days remaining (7 days from first use)
        final likedTracks = await GuestStorageService.getLikedTracks();
        if (likedTracks.isNotEmpty) {
          // Find oldest track to calculate days since first use
          final now = DateTime.now();
          DateTime? oldestDate;

          for (var track in likedTracks) {
            final likedAt = track.likedAt;
            if (oldestDate == null || likedAt.isBefore(oldestDate)) {
              oldestDate = likedAt;
            }
          }

          if (oldestDate != null) {
            final daysPassed = now.difference(oldestDate).inDays;
            final remaining = 7 - daysPassed;
            setState(() {
              _daysRemaining = remaining > 0 ? remaining : 0;
            });
          }
        }
      }
    } catch (e) {
      // If error, keep default value
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warning.withValues(alpha: 0.15),
            AppTheme.secondary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.warning,
                  AppTheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest Mode',
                  style: AppTheme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _daysRemaining > 0
                      ? 'Sign up to save your data permanently (${_daysRemaining == 1 ? '1 day' : '$_daysRemaining days'} remaining)'
                      : 'Your guest data will expire soon. Sign up to keep it!',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Sign up button
          TextButton(
            onPressed: () => context.go('/auth'),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Sign Up',
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Check if guest mode banner should be shown
/// Returns true if user is in guest mode (not authenticated)
Future<bool> shouldShowGuestBanner() async {
  try {
    return await GuestStorageService.hasGuestData();
  } catch (e) {
    return false;
  }
}
