import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for semantic labels and screen reader support
class A11yHelpers {
  /// Wrap a button with semantic label and hint
  static Widget button({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      enabled: enabled,
      child: child,
    );
  }

  /// Wrap an image with semantic label
  static Widget image({
    required Widget child,
    required String label,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }

  /// Wrap a text input with semantic label and hint
  static Widget textField({
    required Widget child,
    required String label,
    String? hint,
    String? value,
  }) {
    return Semantics(
      textField: true,
      label: label,
      hint: hint,
      value: value,
      child: child,
    );
  }

  /// Wrap a header/title with semantic heading
  static Widget header({
    required Widget child,
    required String label,
    bool header = true,
  }) {
    return Semantics(
      header: header,
      label: label,
      child: child,
    );
  }

  /// Wrap a link with semantic label
  static Widget link({
    required Widget child,
    required String label,
    String? hint,
  }) {
    return Semantics(
      link: true,
      label: label,
      hint: hint,
      child: child,
    );
  }

  /// Announce a message to screen readers
  static void announce(BuildContext context, String message) {
    // Use SemanticsService to announce to screen readers
    final view = View.of(context);
    SemanticsService.sendAnnouncement(view, message, TextDirection.ltr);
  }

  /// Create a semantic label for a score/rating
  static String scoreLabel(num score, {num? maxScore, String? unit}) {
    if (maxScore != null) {
      return '${score.toStringAsFixed(1)} out of ${maxScore.toStringAsFixed(0)}${unit != null ? ' $unit' : ''}';
    }
    return '${score.toStringAsFixed(1)}${unit != null ? ' $unit' : ''}';
  }

  /// Create a semantic label for a percentage
  static String percentageLabel(num percentage) {
    return '${percentage.toStringAsFixed(0)} percent';
  }

  /// Create a semantic label for a duration
  static String durationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours hours, $minutes minutes';
    } else if (minutes > 0) {
      return '$minutes minutes, $seconds seconds';
    } else {
      return '$seconds seconds';
    }
  }

  /// Create a semantic label for a date
  static String dateLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  /// Merge semantics for complex widgets
  static Widget merge({
    required Widget child,
    String? label,
    String? value,
    String? hint,
  }) {
    return MergeSemantics(
      child: Semantics(
        label: label,
        value: value,
        hint: hint,
        child: child,
      ),
    );
  }

  /// Exclude semantics from widget tree (for decorative elements)
  static Widget exclude({required Widget child}) {
    return ExcludeSemantics(child: child);
  }
}
