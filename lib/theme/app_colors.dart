import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF3730A3);
  static const accent = Color(0xFF06B6D4);
  static const green = Color(0xFF10B981);
  static const greenDark = Color(0xFF059669);
  static const red = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const background = Color(0xFFF4F6FF);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F2FF);
  static const textPrimary = Color(0xFF1E1B4B);
  static const textMuted = Color(0xFF6B7280);
  static const border = Color(0xFFE0E7FF);

  // Per-category icon background colors (light tint)
  static const catTensesIcon = Color(0xFFEDE9FE);
  static const catModalsIcon = Color(0xFFDBEAFE);
  static const catNounsIcon = Color(0xFFD1FAE5);
  static const catAdjIcon = Color(0xFFFEF3C7);
  static const catStructureIcon = Color(0xFFFCE7F3);
  static const catPrepIcon = Color(0xFFCFFAFE);

  // Per-category gradient stops for headers
  static const List<Color> catTensesGrad = [
    Color(0xFF3730A3),
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
  ];
  static const List<Color> catModalsGrad = [
    Color(0xFF1E40AF),
    Color(0xFF2563EB),
    Color(0xFF4F46E5),
  ];
  static const List<Color> catNounsGrad = [
    Color(0xFF065F46),
    Color(0xFF059669),
    Color(0xFF10B981),
  ];
  static const List<Color> catAdjGrad = [
    Color(0xFF92400E),
    Color(0xFFD97706),
    Color(0xFFF59E0B),
  ];
  static const List<Color> catStructureGrad = [
    Color(0xFF9D174D),
    Color(0xFFDB2777),
    Color(0xFFEC4899),
  ];
  static const List<Color> catPrepGrad = [
    Color(0xFF0E7490),
    Color(0xFF0891B2),
    Color(0xFF06B6D4),
  ];
  static const List<Color> mockTestGrad = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
    Color(0xFF06B6D4),
  ];

  static List<Color> gradientFor(String categoryKey) {
    switch (categoryKey) {
      case 'category_tenses':
        return catTensesGrad;
      case 'category_modals':
        return catModalsGrad;
      case 'category_nouns_pronouns':
        return catNounsGrad;
      case 'category_adjectives_adverbs':
        return catAdjGrad;
      case 'category_structure':
        return catStructureGrad;
      case 'category_prepositions':
        return catPrepGrad;
      default:
        return [primaryDark, primary, primaryLight];
    }
  }

  static Color iconBgFor(String categoryKey) {
    switch (categoryKey) {
      case 'category_tenses':
        return catTensesIcon;
      case 'category_modals':
        return catModalsIcon;
      case 'category_nouns_pronouns':
        return catNounsIcon;
      case 'category_adjectives_adverbs':
        return catAdjIcon;
      case 'category_structure':
        return catStructureIcon;
      case 'category_prepositions':
        return catPrepIcon;
      default:
        return surface2;
    }
  }

  static String emojiFor(String categoryKey) {
    switch (categoryKey) {
      case 'category_tenses':
        return '⏰';
      case 'category_modals':
        return '💬';
      case 'category_nouns_pronouns':
        return '📝';
      case 'category_adjectives_adverbs':
        return '✨';
      case 'category_structure':
        return '🏗️';
      case 'category_prepositions':
        return '📍';
      default:
        return '📖';
    }
  }
}
