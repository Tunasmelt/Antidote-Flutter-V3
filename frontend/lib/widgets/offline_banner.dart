import 'package:flutter/material.dart';

/// Offline mode banner to show when network is unavailable
class OfflineBanner extends StatelessWidget {
  final bool isOnline;

  const OfflineBanner({
    super.key,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withValues(alpha: 0.2),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline. Showing cached data.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Network status provider to check connectivity
class NetworkStatus extends ChangeNotifier {
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  void setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
  }
}
