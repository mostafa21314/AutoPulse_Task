import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'screens/preview_screen.dart';
import 'theme.dart';
import 'widgets/app_header.dart';
import 'widgets/buttons.dart';
import 'widgets/floating_nav_bar.dart';

void main() {
  runApp(const AutoPulseApp());
}

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

  void _onNavigateToTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      UploadScreen(onNavigateToTab: _onNavigateToTab), // placeholder — will be replaced with home screen
      UploadScreen(onNavigateToTab: _onNavigateToTab),
      UploadScreen(onNavigateToTab: _onNavigateToTab), // placeholder — will be replaced with analytics screen
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true, // lets content go behind the floating nav bar
      body: screens[_selectedIndex],
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavigateToTab,
      ),
    );
  }
}

// ─── Upload Screen ────────────────────────────────────────────────────────────
class UploadScreen extends StatelessWidget {
  final ValueChanged<int> onNavigateToTab;

  const UploadScreen({super.key, required this.onNavigateToTab});

  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf', 'heic'];

  void _openPreview(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          filePath: path,
          isPdf: path.toLowerCase().endsWith('.pdf'),
          onNavigateToTab: onNavigateToTab,
        ),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );
    final path = result?.files.single.path;
    if (path == null || !context.mounted) return;
    _openPreview(context, path);
  }

  Future<void> _captureWithCamera(BuildContext context) async {
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null || !context.mounted) return;
    _openPreview(context, photo.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          const AppHeader(),

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
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
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
                  PrimaryButton(
                    label: 'Upload Record',
                    icon: Icons.upload_file_rounded,
                    onTap: () => _pickFile(context),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Capture with Camera',
                    icon: Icons.camera_alt_rounded,
                    onTap: () => _captureWithCamera(context),
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
