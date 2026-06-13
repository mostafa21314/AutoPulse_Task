import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/ocr_service.dart';
import '../theme.dart';
import '../widgets/app_header.dart';
import '../widgets/buttons.dart';
import '../widgets/floating_nav_bar.dart';
import 'results_screen.dart';

/// Shows the picked/captured record so the user can confirm it before
/// running analysis.
class PreviewScreen extends StatelessWidget {
  final String fileName;
  final Uint8List? bytes;
  final bool isPdf;
  final ValueChanged<int> onNavigateToTab;

  const PreviewScreen({
    super.key,
    required this.fileName,
    required this.bytes,
    required this.isPdf,
    required this.onNavigateToTab,
  });

  /// Best-guess MIME type from the file name, for the Gemini request.
  String get _mimeType {
    final name = fileName.toLowerCase();
    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  /// Sends the file to Gemini, shows a loading overlay while it runs, then
  /// opens the results screen (or surfaces an error).
  Future<void> _analyze(BuildContext context) async {
    final data = bytes;
    if (data == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Non-dismissible loading overlay.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    try {
      final record = await OcrService().analyze(data, mimeType: _mimeType);
      navigator.pop(); // dismiss the loader
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            record: record,
            onNavigateToTab: onNavigateToTab,
          ),
        ),
      );
    } catch (e) {
      navigator.pop(); // dismiss the loader
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text('Couldn\'t analyze the record: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
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
                      'Preview',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.accent, letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Looks good?',
                    style: AppTextStyles.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Confirm your record below, then\nanalyze it to extract maintenance details.',
                    style: AppTextStyles.subheadline,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // ── Preview card ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: _PreviewCard(bytes: bytes, isPdf: isPdf, fileName: fileName),
            ),
          ),

          // ── Analyze action ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Analyze',
                    icon: Icons.auto_awesome_rounded,
                    onTap: () => _analyze(context),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Choose a Different File',
                    icon: Icons.replay_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 100), // space above floating nav
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: 1,
        onTap: (i) {
          if (i == 1) {
            Navigator.of(context).pop();
            return;
          }
          Navigator.of(context).pop();
          onNavigateToTab(i);
        },
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Uint8List? bytes;
  final bool isPdf;
  final String fileName;

  const _PreviewCard({
    required this.bytes,
    required this.isPdf,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isPdf ? _PdfPreview(fileName: fileName) : _ImagePreview(bytes: bytes),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List? bytes;
  const _ImagePreview({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: bytes == null
          ? const ColoredBox(color: AppColors.surface)
          : Image.memory(
              bytes!,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
    );
  }
}

class _PdfPreview extends StatelessWidget {
  final String fileName;
  const _PdfPreview({required this.fileName});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentDim,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.accent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fileName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'PDF document',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
