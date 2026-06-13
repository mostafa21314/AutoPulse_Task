import 'package:flutter/material.dart';

import '../models/driving_profile.dart';
import '../models/service_record.dart';
import '../services/schedule_service.dart';
import '../theme.dart';
import '../widgets/app_header.dart';
import '../widgets/buttons.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/service_field_card.dart';
import 'maintenance_schedule_screen.dart';

/// Shows the structured data extracted from an analyzed document: the vehicle
/// identity, followed by an editable service history. The user can fix wrongly
/// extracted rows or add new ones (which slot into chronological order), then
/// move on to creating a maintenance schedule.
class ResultsScreen extends StatefulWidget {
  final ServiceRecord record;
  final ValueChanged<int> onNavigateToTab;

  const ResultsScreen({
    super.key,
    required this.record,
    required this.onNavigateToTab,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final List<ServiceInstant> _services =
      List.of(widget.record.services)..sort(_byDateDesc);

  /// Newest-first comparison. Rows with an unparseable/empty date sink to the
  /// bottom so they don't disrupt the ordered ones.
  int _byDateDesc(ServiceInstant a, ServiceInstant b) {
    final da = _parseDate(a.date);
    final db = _parseDate(b.date);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  }

  /// Parses a `dd/MM/yyyy` date, returning null if it can't.
  DateTime? _parseDate(String s) {
    final parts = s.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    final y = int.tryParse(parts[2].trim());
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  /// Opens the editor for an existing row ([index] set) or a brand-new one,
  /// then re-sorts so the result stays in chronological order.
  Future<void> _editRow({int? index}) async {
    final result = await showModalBottomSheet<ServiceInstant>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceEditorSheet(
        initial: index != null ? _services[index] : null,
      ),
    );
    if (result == null) return;

    setState(() {
      if (index != null) {
        _services[index] = result;
      } else {
        _services.add(result);
      }
      _services.sort(_byDateDesc);
    });
  }

  /// Collects an optional driving profile, asks Gemini to build a schedule from
  /// the current (possibly edited) history, then opens the schedule screen.
  Future<void> _openSchedule() async {
    final profile = await showModalBottomSheet<DrivingProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DrivingProfileSheet(),
    );
    if (profile == null || !mounted) return; // cancelled or disposed

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    try {
      final record = ServiceRecord(
        vehicle: widget.record.vehicle,
        services: _services,
      );
      final schedule = await ScheduleService()
          .generate(record, drivingProfile: profile.describe());
      navigator.pop(); // dismiss the loader
      navigator.push(
        MaterialPageRoute(
          builder: (_) => MaintenanceScheduleScreen(
            schedule: schedule,
            record: record,
            profile: profile,
            onNavigateToTab: widget.onNavigateToTab,
          ),
        ),
      );
    } catch (e) {
      navigator.pop(); // dismiss the loader
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text('Couldn\'t generate schedule: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.record.vehicle;

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
                      'Analysis Complete',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.accent, letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Here\'s what we found',
                    style: AppTextStyles.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Review the details below — tap any service\nto fix it, or add one we missed.',
                    style: AppTextStyles.subheadline,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // ── Vehicle identity ──────────────────────────────────────────────
          const _SectionTitle('Vehicle'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Column(
                children: [
                  ServiceFieldCard(
                    icon: Icons.directions_car_rounded,
                    label: 'Make / Model',
                    value: vehicle.makeModel,
                  ),
                  const SizedBox(height: 10),
                  ServiceFieldCard(
                    icon: Icons.tag_rounded,
                    label: 'VIN / Chassis',
                    value: vehicle.vin,
                  ),
                  const SizedBox(height: 10),
                  ServiceFieldCard(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Plate',
                    value: vehicle.plate,
                  ),
                  const SizedBox(height: 10),
                  ServiceFieldCard(
                    icon: Icons.person_rounded,
                    label: 'Customer',
                    value: vehicle.customer,
                  ),
                  const SizedBox(height: 10),
                  ServiceFieldCard(
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    value: vehicle.phone,
                  ),
                ],
              ),
            ),
          ),

          // ── Service history ───────────────────────────────────────────────
          _SectionTitle('Service History · ${_services.length}'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            sliver: SliverList.separated(
              itemCount: _services.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ServiceCard(
                service: _services[i],
                onEdit: () => _editRow(index: i),
              ),
            ),
          ),

          // ── Actions ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  SecondaryButton(
                    label: 'Add Service Record',
                    icon: Icons.add_rounded,
                    onTap: () => _editRow(),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Create Maintenance Schedule',
                    icon: Icons.calendar_month_rounded,
                    onTap: _openSchedule,
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
          Navigator.of(context).popUntil((r) => r.isFirst);
          widget.onNavigateToTab(i);
        },
      ),
    );
  }
}

/// Section label rendered as its own sliver.
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.textSecondary, letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// One visit — a single row of the service-history table, tappable to edit.
class _ServiceCard extends StatelessWidget {
  final ServiceInstant service;
  final VoidCallback onEdit;
  const _ServiceCard({required this.service, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + odometer header row.
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  service.date.isEmpty ? 'No date' : service.date,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.edit_rounded, size: 16, color: AppColors.accent),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.speed_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  service.odometer.isEmpty ? '—' : service.odometer,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.store_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    service.workshop.isEmpty ? '—' : service.workshop,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (service.workDone.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final job in service.workDone)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentDim,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        job,
                        style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet form for adding or editing a [ServiceInstant]. Returns the new
/// value via `Navigator.pop`, or null if cancelled.
class _ServiceEditorSheet extends StatefulWidget {
  final ServiceInstant? initial;
  const _ServiceEditorSheet({this.initial});

  @override
  State<_ServiceEditorSheet> createState() => _ServiceEditorSheetState();
}

class _ServiceEditorSheetState extends State<_ServiceEditorSheet> {
  late final TextEditingController _date =
      TextEditingController(text: widget.initial?.date ?? '');
  late final TextEditingController _odometer =
      TextEditingController(text: widget.initial?.odometer ?? '');
  late final TextEditingController _workshop =
      TextEditingController(text: widget.initial?.workshop ?? '');
  late final TextEditingController _workDone =
      TextEditingController(text: widget.initial?.workDone.join('\n') ?? '');

  @override
  void dispose() {
    _date.dispose();
    _odometer.dispose();
    _workshop.dispose();
    _workDone.dispose();
    super.dispose();
  }

  void _save() {
    final jobs = _workDone.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    Navigator.of(context).pop(
      ServiceInstant(
        date: _date.text.trim(),
        odometer: _odometer.text.trim(),
        workshop: _workshop.text.trim(),
        workDone: jobs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEditing ? 'Edit service' : 'Add service',
                style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _field(label: 'Date', controller: _date, hint: 'dd/MM/yyyy'),
              _field(label: 'Odometer', controller: _odometer, hint: 'e.g. 196,772 km'),
              _field(label: 'Workshop', controller: _workshop, hint: 'Service center name'),
              _field(
                label: 'Work done',
                controller: _workDone,
                hint: 'One job per line',
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: isEditing ? 'Save Changes' : 'Add Service',
                icon: Icons.check_rounded,
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary, letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet that collects the owner's driving profile as explicit choices
/// before generating a schedule. Returns a [DrivingProfile] via `Navigator.pop`,
/// or null if cancelled.
class _DrivingProfileSheet extends StatefulWidget {
  const _DrivingProfileSheet();

  @override
  State<_DrivingProfileSheet> createState() => _DrivingProfileSheetState();
}

class _DrivingProfileSheetState extends State<_DrivingProfileSheet> {
  // Defaults to the gentler option on each axis.
  bool _overspeeding = false;
  bool _offRoad = false;
  bool _suddenBraking = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your driving profile',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tell us how and where you drive so we can tune the schedule.',
              style: AppTextStyles.subheadline,
            ),
            const SizedBox(height: 20),
            _ChoiceRow(
              label: 'Speed',
              leftLabel: 'Normal',
              rightLabel: 'Overspeeding',
              value: _overspeeding,
              onChanged: (v) => setState(() => _overspeeding = v),
            ),
            const SizedBox(height: 16),
            _ChoiceRow(
              label: 'Environment',
              leftLabel: 'Urban',
              rightLabel: 'Off-road',
              value: _offRoad,
              onChanged: (v) => setState(() => _offRoad = v),
            ),
            const SizedBox(height: 16),
            _ChoiceRow(
              label: 'Braking',
              leftLabel: 'Smooth',
              rightLabel: 'Sudden',
              value: _suddenBraking,
              onChanged: (v) => setState(() => _suddenBraking = v),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Generate Schedule',
              icon: Icons.auto_awesome_rounded,
              onTap: () => Navigator.of(context).pop(
                DrivingProfile(
                  overspeeding: _overspeeding,
                  offRoad: _offRoad,
                  suddenBraking: _suddenBraking,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled two-option segmented toggle. `false` selects the left option,
/// `true` the right.
class _ChoiceRow extends StatelessWidget {
  final String label;
  final String leftLabel;
  final String rightLabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ChoiceRow({
    required this.label,
    required this.leftLabel,
    required this.rightLabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: AppColors.textSecondary, letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
          ),
          child: Row(
            children: [
              _segment(leftLabel, selected: !value, onTap: () => onChanged(false)),
              _segment(rightLabel, selected: value, onTap: () => onChanged(true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _segment(String text, {required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
