import 'dart:convert';
import 'package:flutter/material.dart';

/// Service for generating consistent avatar placeholders with initials and colors
class AvatarService {
  // Predefined color palette for avatar backgrounds
  static const List<Color> _colorPalette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF97316), // Orange
    Color(0xFF84CC16), // Lime
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo-500
    Color(0xFFDB2777), // Pink-600
    Color(0xFFDC2626), // Red-600
    Color(0xFFCA8A04), // Yellow-600
    Color(0xFF059669), // Green-600
    Color(0xFF0891B2), // Cyan-600
    Color(0xFF2563EB), // Blue-600
    Color(0xFF7C3AED), // Violet-600
  ];

  // Additional pastel colors for variety
  static const List<Color> _pastelPalette = [
    Color(0xFFFFB3BA), // Light Pink
    Color(0xFFFFDFBA), // Light Orange
    Color(0xFFFFFFBA), // Light Yellow
    Color(0xFFBAFFBA), // Light Green
    Color(0xFFBAE1FF), // Light Blue
    Color(0xFFE1BAFF), // Light Purple
    Color(0xFFFFBAE1), // Light Magenta
    Color(0xFFBAFFE1), // Light Mint
    Color(0xFFFFC9BA), // Light Peach
    Color(0xFFD4BAFF), // Light Lavender
  ];

  // Combined color palette
  static final List<Color> _allColors = [..._colorPalette, ..._pastelPalette];

  /// Get initials from a full name
  /// Examples:
  /// - "John Doe" -> "JD"
  /// - "Alice Johnson Smith" -> "AJ" (first and last)
  /// - "John" -> "J"
  /// - "" -> "U" (Unknown)
  static String getInitials(String fullName) {
    if (fullName.trim().isEmpty) return 'U';
    
    final words = fullName.trim().split(RegExp(r'\s+'));
    
    if (words.length >= 2) {
      // Use first and last name initials
      final first = words.first;
      final last = words.last;
      return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'.toUpperCase();
    } else if (words.isNotEmpty && words.first.isNotEmpty) {
      // Single name, use first character
      return words.first[0].toUpperCase();
    }
    
    return 'U';
  }

  /// Generate a deterministic color based on user identifier
  /// This ensures the same user always gets the same color
  static Color getDeterministicColor(String identifier) {
    if (identifier.isEmpty) return _allColors.first;
    
    // Create a hash of the identifier
    final bytes = utf8.encode(identifier.toLowerCase());
    var hash = 0;
    for (final byte in bytes) {
      hash = ((hash << 5) - hash) + byte;
      hash = hash & hash; // Convert to 32-bit integer
    }
    
    // Use absolute value to ensure positive index
    final index = hash.abs() % _allColors.length;
    return _allColors[index];
  }

  /// Generate a slightly darker version of a color for gradients
  static Color getDarkerShade(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }

  /// Get contrasting text color (white or black) based on background color
  static Color getContrastingTextColor(Color backgroundColor) {
    // Calculate luminance
    final luminance = backgroundColor.computeLuminance();
    // Return white for dark backgrounds, black for light backgrounds
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Create avatar data for a user
  static AvatarData createAvatarData({
    required String identifier,
    required String displayName,
    String? avatarUrl,
  }) {
    final initials = getInitials(displayName);
    final backgroundColor = getDeterministicColor(identifier);
    final gradientColor = getDarkerShade(backgroundColor);
    final textColor = getContrastingTextColor(backgroundColor);

    return AvatarData(
      identifier: identifier,
      displayName: displayName,
      initials: initials,
      avatarUrl: avatarUrl,
      backgroundColor: backgroundColor,
      gradientColor: gradientColor,
      textColor: textColor,
    );
  }

  /// Validate if a URL appears to be a valid image URL
  static bool isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    
    // Basic URL validation
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    // Check for common image extensions
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.contains(RegExp(r'\.(jpg|jpeg|png|gif|webp|svg)(\?|$)')) ||
           lowercaseUrl.contains('image') ||
           lowercaseUrl.contains('avatar') ||
           lowercaseUrl.contains('profile');
  }

  /// Get color palette for UI display (useful for settings/preferences)
  static List<Color> getColorPalette() => List.from(_allColors);

  /// Test function to preview how different names will look
  static Map<String, AvatarData> generateTestAvatars() {
    final testNames = [
      'John Doe',
      'Alice Johnson',
      'Michael Smith',
      'Sarah Wilson',
      'David Brown',
      'Emma Davis',
      'James Miller',
      'Olivia Garcia',
      'William Martinez',
      'Sophia Anderson',
    ];

    final Map<String, AvatarData> results = {};
    for (int i = 0; i < testNames.length; i++) {
      final name = testNames[i];
      results[name] = createAvatarData(
        identifier: 'user_$i',
        displayName: name,
      );
    }
    return results;
  }
}

/// Data class containing all avatar information
class AvatarData {
  final String identifier;
  final String displayName;
  final String initials;
  final String? avatarUrl;
  final Color backgroundColor;
  final Color gradientColor;
  final Color textColor;

  const AvatarData({
    required this.identifier,
    required this.displayName,
    required this.initials,
    this.avatarUrl,
    required this.backgroundColor,
    required this.gradientColor,
    required this.textColor,
  });

  /// Whether this avatar has a valid image URL
  bool get hasValidImage => AvatarService.isValidImageUrl(avatarUrl);

  @override
  String toString() {
    return 'AvatarData(identifier: $identifier, name: $displayName, initials: $initials, hasImage: $hasValidImage)';
  }
}