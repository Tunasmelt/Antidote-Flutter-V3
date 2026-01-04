import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/api_client_provider.dart';

class PlaylistGeneratorScreen extends ConsumerStatefulWidget {
  const PlaylistGeneratorScreen({super.key});

  @override
  ConsumerState<PlaylistGeneratorScreen> createState() => _PlaylistGeneratorScreenState();
}

class _PlaylistGeneratorScreenState extends ConsumerState<PlaylistGeneratorScreen> {
  String? _selectedMood;
  String? _selectedActivity;
  String? _selectedType;
  List<Map<String, dynamic>>? _generatedPlaylist;
  bool _isGenerating = false;

  final List<String> _moods = [
    'happy',
    'chill',
    'intense',
    'melancholic',
    'energetic',
    'relaxed',
  ];

  final List<String> _activities = [
    'workout',
    'study',
    'party',
    'work',
    'commute',
    'sleep',
  ];

  final List<String> _types = [
    'mood_based',
    'activity_based',
    'taste_based',
    'discovery',
  ];

  Future<void> _generatePlaylist() async {
    if (_selectedMood == null && _selectedActivity == null && _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one option'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedPlaylist = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.generatePlaylist(
        type: _selectedType,
        mood: _selectedMood,
        activity: _selectedActivity,
        limit: 30,
      );

      if (mounted) {
        setState(() {
          _generatedPlaylist = (result['tracks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate playlist: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/'),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Smart Playlist Generator',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Type Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Playlist Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _types.map((type) {
                        final isSelected = _selectedType == type;
                        return FilterChip(
                          selected: isSelected,
                          label: Text(type.replaceAll('_', ' ').toUpperCase()),
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = selected ? type : null;
                            });
                          },
                          selectedColor: AppTheme.primary.withValues(alpha: 0.3),
                          checkmarkColor: AppTheme.primary,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Mood Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _moods.map((mood) {
                        final isSelected = _selectedMood == mood;
                        return FilterChip(
                          selected: isSelected,
                          label: Text(mood.toUpperCase()),
                          onSelected: (selected) {
                            setState(() {
                              _selectedMood = selected ? mood : null;
                            });
                          },
                          selectedColor: AppTheme.secondary.withValues(alpha: 0.3),
                          checkmarkColor: AppTheme.secondary,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Activity Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _activities.map((activity) {
                        final isSelected = _selectedActivity == activity;
                        return FilterChip(
                          selected: isSelected,
                          label: Text(activity.toUpperCase()),
                          onSelected: (selected) {
                            setState(() {
                              _selectedActivity = selected ? activity : null;
                            });
                          },
                          selectedColor: AppTheme.warning.withValues(alpha: 0.3),
                          checkmarkColor: AppTheme.warning,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Generate Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generatePlaylist,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.playlist_add),
                    label: Text(
                      _isGenerating ? 'Generating...' : 'Generate Playlist',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              // Create Playlist Button (shown when playlist is generated)
              if (_generatedPlaylist != null && _generatedPlaylist!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreatePlaylistDialog(context),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create Spotify Playlist'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Generated Playlist
              if (_generatedPlaylist != null && _generatedPlaylist!.isNotEmpty) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Generated Playlist',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_generatedPlaylist!.length} tracks',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                              fontFamily: 'Space Mono',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._generatedPlaylist!.map((track) {
                        final name = track['name']?.toString() ?? 'Unknown';
                        final artists = (track['artists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                        final artistName = artists.isNotEmpty
                            ? artists.map((a) => a['name']?.toString() ?? '').join(', ')
                            : 'Unknown Artist';
                        final albumArt = track['album']?['images']?[0]?['url'] ??
                                        track['albumArt']?.toString();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: albumArt != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          albumArt.toString(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
                                        ),
                                      )
                                    : const Icon(Icons.music_note),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      artistName,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    if (_generatedPlaylist == null || _generatedPlaylist!.isEmpty) return;

    final nameController = TextEditingController();
    String playlistType = 'Smart Playlist';
    if (_selectedMood != null) {
      playlistType = '${_selectedMood!.toUpperCase()} Mood';
    } else if (_selectedActivity != null) {
      playlistType = '${_selectedActivity!.toUpperCase()} Activity';
    }
    nameController.text = playlistType;

    final descriptionController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Create Spotify Playlist',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.textMuted),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.textMuted),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              '${_generatedPlaylist!.length} tracks will be added',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
                fontFamily: 'Space Mono',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'description': descriptionController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result['name'] != null && result['name']!.toString().isNotEmpty) {
      if (!mounted || !context.mounted) return;
      _createPlaylist(context, result['name']!.toString(), result['description']?.toString());
    }
  }

  Future<void> _createPlaylist(BuildContext context, String name, String? description) async {
    if (_generatedPlaylist == null || _generatedPlaylist!.isEmpty) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      
      // Convert generated tracks to track format
      final tracks = _generatedPlaylist!.map((track) {
        return {
          'id': track['id']?.toString(),
          'uri': track['uri']?.toString() ?? 'spotify:track:${track['id']}',
        };
      }).toList();

      await apiClient.createPlaylist(
        name: name,
        description: description,
        tracks: tracks,
      );

      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playlist "$name" created successfully!'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create playlist: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

