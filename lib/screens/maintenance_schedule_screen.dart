import 'package:flutter/material.dart';

import '../models/driving_profile.dart';
import '../models/maintenance_schedule.dart';
import '../models/service_record.dart';
import '../services/schedule_pdf_service.dart';
import '../theme.dart';
import '../widgets/app_header.dart';
import '../widgets/buttons.dart';
import '../widgets/floating_nav_bar.dart';

/// Final screen: the forward-looking maintenance schedule Gemini generated from
/// the service history and the owner's driving profile, plus the option to
/// export the PDF deliverable (built from hard-coded modelling logic).
class MaintenanceScheduleScreen extends StatelessWidget {
  final MaintenanceSchedule schedule;
  final ServiceRecord record;
  final DrivingProfile profile;
  final ValueChanged<int> onNavigateToTab;

  const MaintenanceScheduleScreen({
    super.key,
    required this.schedule,
    required this.record,
    required this.profile,
    required this.onNavigateToTab,
  });

  Future<void> _generatePdf(BuildContext context) async {
    final navigator = Navigator.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    try {
      await SchedulePdfService().generate(record: record, profile: profile);
      navigator.pop(); // dismiss the loader
    } catch (e, st) {
      navigator.pop(); // dismiss the loader
      // ignore: avoid_print
      print('PDF generation failed: $e\n$st');
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('PDF generation failed',
              style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: SelectableText(
              '$e',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
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
                      'Maintenance Schedule',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.accent, letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'What\'s coming up',
                    style: AppTextStyles.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upcoming services predicted for your\n${record.vehicle.makeModel}.',
                    style: AppTextStyles.subheadline,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // ── Schedule ──────────────────────────────────────────────────────
          if (schedule.items.isEmpty)
            const SliverToBoxAdapter(child: _EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              sliver: SliverList.separated(
                itemCount: schedule.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ScheduleCard(item: schedule.items[i]),
              ),
            ),

          // ── PDF deliverable ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: PrimaryButton(
                label: 'Generate Schedule PDF',
                icon: Icons.picture_as_pdf_rounded,
                onTap: () => _generatePdf(context),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: 2,
        onTap: (i) {
          Navigator.of(context).popUntil((r) => r.isFirst);
          onNavigateToTab(i);
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 60, 24, 0),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'No upcoming services',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'We couldn\'t derive a schedule from this record.',
            style: AppTextStyles.subheadline,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// One upcoming service.
class _ScheduleCard extends StatelessWidget {
  final MaintenanceItem item;
  const _ScheduleCard({required this.item});

  /// Colour cue per priority.
  Color get _priorityColor {
    switch (item.priority) {
      case 'high':
        return const Color(0xFFFF6B6B);
      case 'low':
        return AppColors.textSecondary;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.task,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _priorityColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  item.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: _priorityColor, letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_rounded, size: 15, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                item.dueDate.isEmpty ? '—' : item.dueDate,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.speed_rounded, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.dueOdometer.isEmpty ? '—' : item.dueOdometer,
                  style: AppTextStyles.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 12),
            Text(
              item.notes,
              style: const TextStyle(
                fontSize: 13, height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
