import 'package:flutter/material.dart';

class AppColor {
  // ✅ 1. Background
  static const Color background = Color(0xFFFDFDFD); // Off White
  
  // ✅ 2. Primary Color (Headers, Highlights, Buttons)
  static const Color primary = Color(0xFF1E3A8A); // Dark Blue
  static const Color primarySoft = Color(0xFFEBF3FE); // Light blue tint for soft backgrounds
  
  // ✅ 3. Accent Color
  static const Color accent = Color(0xFF3B82F6); // Blue-500
  static const Color accentLight = Color(0xFF60A5FA); // Blue-400 for hover states
  
  // Legacy secondary color (keeping for compatibility)
  static const Color secondary = Color(0xFF1E3A8A); // Same as primary for consistency
  
  // ✅ 4. Text Colors
  static const Color textPrimary = Color(0xFF1F2937); // Dark gray for primary text
  static const Color textSecondary = Color(0xFF6B7280); // Gray for secondary text
  static const Color textLight = Color(0xFFFFFFFF); // White text for dark backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on primary backgrounds
  static const Color placeholder = Color(0xFF9CA3AF); // Placeholder text
  
  // Legacy text colors (keeping for compatibility, but mapping to new colors)
  static const Color textDark = Color(0xFF1F2937); // Maps to textPrimary
  static const Color textBlack = Color(0xFF1F2937); // Maps to textPrimary
  static const Color textMedium = Color(0xFF6B7280); // Maps to textSecondary
  
  // ✅ 5. Disabled or Inactive Elements
  static const Color disabled = Color(0xFFE5E7EB); // Light gray
  static const Color inactive = Color(0xFFE5E7EB);
  
  // ✅ 6. Borders and Dividers
  static const Color border = Color(0xFFCBD5E1); // Border color
  static const Color borderLight = Color(0xFFE5E7EB); // Lighter border
  static const Color divider = Color(0xFFE5E7EB);
  
  // ✅ 7. Form Elements
  static const Color inputBorder = Color(0xFFCBD5E1); // Input borders
  static const Color inputFocusBorder = Color(0xFF1E3A8A); // Focus border
  static const Color inputBackground = Color(0xFFFDFDFD); // Input background
  
  // Status Colors
  static const Color success = Color(0xFF10B981); // Green for success states
  static const Color warning = Color(0xFFF59E0B); // Amber for warning states
  static const Color error = Color(0xFFEF4444); // Red for error states
  
  // Surface and Card Colors
  static const Color surface = Color(0xFFFDFDFD); // Same as background
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white for cards
  
  // Icon Colors
  static const Color iconPrimary = Color(0xFF1E3A8A); // Primary icons
  static const Color iconSecondary = Color(0xFF6B7280); // Secondary icons
  static const Color iconLight = Color(0xFFFFFFFF); // Light icons
  static const Color iconDark = Color(0xFF1F2937); // Dark icons
  
  // Shadow Color
  static const Color shadowColor = Color(0x1A1E3A8A); // rgba(30, 58, 138, 0.1)
}
