import 'package:flutter/material.dart';

class AppTheme {
  // Main color palette
  static const Color primaryColor = Color(0xFFA47864); // Brown
  static const Color secondaryColor = Color(0xFF5C6B73); // Blue-gray
  static const Color backgroundColor = Color(0xFFFFF4E9); // Light cream

  // Derived/complementary colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color dividerColor = Color(0xFFEEEEEE);
  static const Color accentColor = Color(0xFF8A5A44); // Darker brown for accents

  // Create a ThemeData instance
  static ThemeData get themeData {
    return ThemeData(
      // Base colors
      primarySwatch: Colors.blue, // Keep your existing primarySwatch
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: textPrimary, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
      ),
      
      // Tab bar theme
      tabBarTheme: const TabBarTheme(
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        displayLarge: TextStyle(color: textPrimary),
        displayMedium: TextStyle(color: textPrimary),
        displaySmall: TextStyle(color: textPrimary),
        headlineMedium: TextStyle(color: textPrimary),
        headlineSmall: TextStyle(color: textPrimary),
        titleLarge: TextStyle(color: textPrimary),
        titleMedium: TextStyle(color: textPrimary),
        titleSmall: TextStyle(color: textPrimary),
        bodyLarge: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: primaryColor),
        labelSmall: TextStyle(color: textSecondary),
      ),
      
      // Navigation bar theme - from your existing code
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: primaryColor, // Brown color for NavigationBar
        elevation: 10, // Adds a shadow effect
        indicatorColor: backgroundColor, // Cream color for indicator
        
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(
                color: primaryColor, // Brown color when selected
                size: 30, // Large icon when selected
              );
            }
            return IconThemeData(
              color: backgroundColor, // Cream color when unselected
              size: 24, // Smaller icon when unselected
            );
          },
        ),

        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: backgroundColor, // Cream color for labels
            fontSize: 12,
          ),
        ),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: primaryColor,
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withValues(alpha: 26),
        disabledColor: Colors.grey.shade300,
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        labelStyle: const TextStyle(color: textPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.light,
      ),
      
      // Color scheme
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,

        onError: Colors.white,
        brightness: Brightness.light,
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }
}