import 'package:flutter/material.dart';

// ─── Brand tokens ─────────────────────────────────────────────────────────────
class AppColors {
  static const background    = Color(0xFF1C2532);
  static const surface       = Color(0xFF243040);
  static const surfaceDeep   = Color(0xFF1A2030);
  static const accent        = Color(0xFF00C4CC);
  static const accentDim     = Color(0x1A00C4CC);
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF7A8FA6);
  static const divider       = Color(0xFF00C4CC);
  static const cardBorder    = Color(0xFF2E3D52);
}

class AppTextStyles {
  static const headline = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.5,
  );
  static const subheadline = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.6,
  );
  static const buttonLabel = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.3,
  );
  static const caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, letterSpacing: 0.2,
  );
}
