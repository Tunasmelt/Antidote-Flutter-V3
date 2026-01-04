import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';

/// A reusable widget that prompts users to connect their Spotify account
/// Shows when features require Spotify token but user hasn't connected yet
class SpotifyConnectPrompt extends ConsumerWidget {
  final String message;
  final VoidCallback? onConnected;
  final bool showCancelButton;

  const SpotifyConnectPrompt({
    super.key,
    this.message = 'Connect your Spotify account to use this feature',
    this.onConnected,
    this.showCancelButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cardBackground,
              AppTheme.cardBackground.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spotify logo icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1DB954),
                    Color(0xFF1ED760),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Spotify Required',
              style: AppTheme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Connect button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final authService = AuthService();
                    await authService.signInWithSpotify(useDirectOAuth: true);

                    // Call callback if provided
                    if (onConnected != null) {
                      onConnected!();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Failed to connect Spotify: ${e.toString()}'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Connect Spotify',
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel button
            if (showCancelButton)
              TextButton(
                onPressed: () {
                  // Try to navigate back using GoRouter first
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    // Fallback to Navigator
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      // If can't pop, go to home
                      context.go('/');
                    }
                  }
                },
                child: Text(
                  'Maybe Later',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Show Spotify connect dialog
Future<void> showSpotifyConnectDialog({
  required BuildContext context,
  String? message,
  VoidCallback? onConnected,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: SpotifyConnectPrompt(
        message: message ?? 'Connect your Spotify account to use this feature',
        onConnected: onConnected,
      ),
    ),
  );
}
