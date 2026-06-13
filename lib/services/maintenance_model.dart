import 'dart:math';

import '../models/driving_profile.dart';
import '../models/service_record.dart';

/// One factor (driving characteristic) that shortens or extends a component's
/// service interval, with a short reason for the PDF.
class FactorAdjustment {
  final String reason;
  final double multiplier;
  const FactorAdjustment(this.reason, this.multiplier);
}

/// A tracked maintenance component: its manufacturer baseline interval, the
/// history keywords used as a matching fallback, and the per-profile factors
/// that adjust its interval.
class MaintenanceComponent {
  final String id;
  final String name;
  final int baselineKm;
  final List<String> keywords;
  final List<FactorAdjustment> Function(DrivingProfile) factorBuilder;

  const MaintenanceComponent({
    required this.id,
    required this.name,
    required this.baselineKm,
    required this.keywords,
    required this.factorBuilder,
  });

  /// Factors that apply for the given profile (empty = no adjustment).
  List<FactorAdjustment> factors(DrivingProfile p) => factorBuilder(p);

  /// Net multiplier = product of the applicable factor multipliers.
  double multiplier(DrivingProfile p) =>
      factors(p).fold(1.0, (m, f) => m * f.multiplier);

  /// adjusted_interval = baseline x multiplier, rounded to a tidy 500 km.
  int adjustedKm(DrivingProfile p) {
    final v = baselineKm * multiplier(p);
    return (v / 500).round() * 500;
  }
}

enum ServiceStatus { overdue, dueSoon, scheduled }

/// One projected occurrence of a service within the horizon.
class ScheduledService {
  final String item;
  final int dueAtKm;
  final ServiceStatus status;

  const ScheduledService({
    required this.item,
    required this.dueAtKm,
    required this.status,
  });
}

/// Per-component standing: interval, last-done, next-due, status, and the
/// factors that produced the adjusted interval.
class ItemStatus {
  final MaintenanceComponent component;
  final List<FactorAdjustment> factors;
  final double multiplier;
  final int intervalKm;
  final int lastDoneKm;
  final int nextDueKm;
  final ServiceStatus status;

  const ItemStatus({
    required this.component,
    required this.factors,
    required this.multiplier,
    required this.intervalKm,
    required this.lastDoneKm,
    required this.nextDueKm,
    required this.status,
  });
}

/// The computed plan handed to the PDF builder.
class MaintenancePlan {
  final int currentOdoKm;
  final int horizonKm;
  final List<ItemStatus> statuses;
  final List<ScheduledService> schedule;

  const MaintenancePlan({
    required this.currentOdoKm,
    required this.horizonKm,
    required this.statuses,
    required this.schedule,
  });
}

/// Implements the deliverable's modelling + scheduling rules.
class MaintenanceModel {
  /// Schedule horizon: the next 80,000 km from the current odometer.
  static const horizonKm = 80000;

  /// The tracked components and how each driving factor adjusts them.
  static final List<MaintenanceComponent> components = [
    MaintenanceComponent(
      id: 'engine_oil',
      name: 'Engine oil',
      baselineKm: 10000,
      keywords: ['engine oil', 'oil change', 'oil & filter', 'زيت'],
      factorBuilder: (p) => [
        if (p.overspeeding)
          const FactorAdjustment('Overspeeding -> high RPM/heat', 0.7),
      ],
    ),
    MaintenanceComponent(
      id: 'oil_filter',
      name: 'Oil filter',
      baselineKm: 10000,
      keywords: ['oil filter', 'filter oil', 'فلتر زيت'],
      factorBuilder: (p) => [
        if (p.overspeeding)
          const FactorAdjustment('Tracks engine oil interval', 0.7),
      ],
    ),
    MaintenanceComponent(
      id: 'air_filter',
      name: 'Air filter',
      baselineKm: 15000,
      keywords: ['air filter', 'فلتر هواء'],
      factorBuilder: (p) => [
        if (p.offRoad)
          const FactorAdjustment('Off-road dust ingestion', 0.6)
        else
          const FactorAdjustment('Urban (Cairo) dust', 0.7),
      ],
    ),
    MaintenanceComponent(
      id: 'shock_absorbers',
      name: 'Shock absorbers',
      baselineKm: 50000,
      keywords: ['shock', 'absorber', 'مساعد'],
      factorBuilder: (p) => [
        if (p.offRoad)
          const FactorAdjustment('Off-road impacts', 0.5)
        else
          const FactorAdjustment('Urban speed bumps', 0.7),
        if (p.suddenBraking)
          const FactorAdjustment('Hard braking nose-dive', 0.9),
      ],
    ),
    MaintenanceComponent(
      id: 'brake_pads',
      name: 'Brake pads',
      baselineKm: 30000,
      keywords: ['brake pad', 'brake', 'فرامل', 'تيل'],
      factorBuilder: (p) => [
        if (p.suddenBraking)
          const FactorAdjustment('Sudden braking -> more wear', 0.7)
        else
          const FactorAdjustment('Smooth braking -> less wear', 1.33),
      ],
    ),
    MaintenanceComponent(
      id: 'coolant',
      name: 'Coolant',
      baselineKm: 40000,
      keywords: ['coolant', 'radiator', 'تبريد', 'كولنت'],
      factorBuilder: (p) => [
        if (p.overspeeding)
          const FactorAdjustment('Overspeeding -> heat stress', 0.75),
        if (!p.offRoad)
          const FactorAdjustment('Urban idling heat', 0.85),
      ],
    ),
    MaintenanceComponent(
      id: 'tyre_rotation',
      name: 'Tyres rotation',
      baselineKm: 10000,
      keywords: ['tyre', 'tire', 'rotation', 'اطار', 'كاوتش'],
      factorBuilder: (p) => [
        if (p.overspeeding)
          const FactorAdjustment('Overspeeding -> uneven wear', 0.7),
        if (p.offRoad)
          const FactorAdjustment('Off-road abrasion', 0.85),
        if (p.suddenBraking)
          const FactorAdjustment('Hard braking flat-spotting', 0.9),
      ],
    ),
    MaintenanceComponent(
      id: 'spark_plugs',
      name: 'Spark plugs',
      baselineKm: 30000,
      keywords: ['spark plug', 'spark', 'بوجيه'],
      factorBuilder: (p) => [
        if (p.overspeeding)
          const FactorAdjustment('High RPM electrode stress', 0.7),
      ],
    ),
  ];

  /// Builds the maintenance plan from the extracted [record] and the owner's
  /// driving [profile].
  static MaintenancePlan build(ServiceRecord record, DrivingProfile profile) {
    final currentOdo = _currentOdo(record);
    final upper = currentOdo + horizonKm;

    final statuses = <ItemStatus>[];
    final schedule = <ScheduledService>[];

    for (final c in components) {
      final interval = c.adjustedKm(profile);
      if (interval <= 0) continue;

      // Cross-validate the history (newest first) to find when this component
      // was last actually serviced; if never, baseline from the current
      // odometer so it schedules forward rather than reading as overdue.
      final lastDone = _lastDoneFor(c, record) ?? currentOdo;
      final nextDue = lastDone + interval;

      statuses.add(ItemStatus(
        component: c,
        factors: c.factors(profile),
        multiplier: c.multiplier(profile),
        intervalKm: interval,
        lastDoneKm: lastDone,
        nextDueKm: nextDue,
        status: _statusOf(currentOdo, nextDue),
      ));

      // Surface an already-passed next due once.
      if (currentOdo > nextDue) {
        schedule.add(ScheduledService(
          item: c.name,
          dueAtKm: nextDue,
          status: ServiceStatus.overdue,
        ));
      }

      // Future occurrences within the 80,000 km horizon.
      for (var k = 1; k <= 1000; k++) {
        final due = lastDone + k * interval;
        if (due > upper) break;
        if (due >= currentOdo) {
          schedule.add(ScheduledService(
            item: c.name,
            dueAtKm: due,
            status: _statusOf(currentOdo, due),
          ));
        }
      }
    }

    schedule.sort((a, b) => a.dueAtKm.compareTo(b.dueAtKm));

    return MaintenancePlan(
      currentOdoKm: currentOdo,
      horizonKm: horizonKm,
      statuses: statuses,
      schedule: schedule,
    );
  }

  static ServiceStatus _statusOf(int currentOdo, int dueAt) {
    if (currentOdo > dueAt) return ServiceStatus.overdue;
    if (currentOdo > dueAt - 1000) return ServiceStatus.dueSoon;
    return ServiceStatus.scheduled;
  }

  /// Current mileage = the highest odometer reading in the history.
  static int _currentOdo(ServiceRecord record) {
    final odos = record.services
        .map((s) => _parseKm(s.odometer))
        .whereType<int>()
        .toList();
    return odos.isEmpty ? 0 : odos.reduce(max);
  }

  /// Highest odometer among services that covered this component — matched on
  /// Gemini's component tags, falling back to history keywords.
  static int? _lastDoneFor(MaintenanceComponent c, ServiceRecord record) {
    int? best;
    for (final s in record.services) {
      final odo = _parseKm(s.odometer);
      if (odo == null) continue;
      final covered = s.components.contains(c.id) ||
          c.keywords.any(s.workDone.join(' ').toLowerCase().contains);
      if (covered && (best == null || odo > best)) best = odo;
    }
    return best;
  }

  /// Extracts the integer km from strings like "196,772 km".
  static int? _parseKm(String s) {
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }
}
