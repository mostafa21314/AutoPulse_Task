import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

void main() {
  runApp(const AutoPulseApp());
}

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
// ──────────────────────────────────────────────────────────────────────────────

class AutoPulseApp extends StatelessWidget {
  const AutoPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return MaterialApp(
      title: 'AutoPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surface,
        ),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

// ─── Main Shell — holds bottom nav state ──────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _screens = [
    UploadScreen(),
    UploadScreen(), // placeholder — will be replaced with analytics screen
    UploadScreen(), // placeholder — will be replaced with home screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true, // lets content go behind the floating nav bar
      body: _screens[_selectedIndex],
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ─── Floating Nav Bar ─────────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_rounded,         label: 'Home'),
    _NavItem(icon: Icons.upload_file_rounded,  label: 'Upload'),
    _NavItem(icon: Icons.bar_chart_rounded,    label: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surfaceDeep.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.cardBorder.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final selected = i == selectedIndex;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Active indicator dot above icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          width: selected ? 20 : 0,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Icon(
                          _items[i].icon,
                          size: 22,
                          color: selected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─── Upload Screen ────────────────────────────────────────────────────────────
class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [

          // ── Header ────────────────────────────────────────────────────────
          SliverAppBar(
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
                    errorBuilder: (_, __, ___) => const Text(
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
          ),

          // ── Hero ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Maintenance Records',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.accent, letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Never worry about\nremembering\nmaintenance dates.',
                    style: AppTextStyles.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AutoPulse reads your service records\nautomatically and keeps your car\'s\nhistory in one place.',
                    style: AppTextStyles.subheadline,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // ── CTA ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 52, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'GET STARTED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary, letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1, color: AppColors.cardBorder),
                  const SizedBox(height: 28),
                  const Text(
                    'Get started by uploading\na maintenance record.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary, height: 1.35, letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Supports photos, scans, and PDF files.\nWorks with handwritten and printed records.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subheadline,
                  ),
                  const SizedBox(height: 32),
                  _PrimaryButton(
                    label: 'Upload Record',
                    icon: Icons.upload_file_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _SecondaryButton(
                    label: 'Capture with Camera',
                    icon: Icons.camera_alt_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text('JPG · PNG · PDF · HEIC', style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 100), // space above floating nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Buttons ──────────────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.30),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.buttonLabel),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceDeep,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.buttonLabel),
          ],
        ),
      ),
    );
  }
}