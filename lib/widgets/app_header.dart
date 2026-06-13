import 'package:flutter/material.dart';
import '../theme.dart';

/// Shared logo + menu header, used as the first sliver on every screen.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 0,
      toolbarHeight: 64,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
      flexibleSpace: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 36,
              errorBuilder: (_, _, _) => const Text(
                'AUTOPULSE',
                style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: AppColors.accent, letterSpacing: 1.2,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.textPrimary, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
