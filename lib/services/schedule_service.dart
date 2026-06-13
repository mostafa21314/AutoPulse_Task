import 'dart:convert';

import '../models/maintenance_schedule.dart';
import '../models/service_record.dart';
import 'gemini_client.dart';

/// Asks Gemini to turn a vehicle's service history (plus the owner's optional
/// driving profile) into a forward-looking [MaintenanceSchedule].
class ScheduleService {
  final GeminiClient _gemini = GeminiClient();

  /// Generates the upcoming-maintenance schedule. [drivingProfile] is free
  /// text the owner writes about how/where they drive, used to adjust
  /// intervals; pass an empty string to skip it.
  Future<MaintenanceSchedule> generate(
    ServiceRecord record, {
    String drivingProfile = '',
  }) async {
    final history =
        const JsonEncoder.withIndent('  ').convert(record.toJson());
    final profile = drivingProfile.trim().isEmpty
        ? 'No specific driving profile provided.'
        : drivingProfile.trim();

    final prompt = '''
You are a vehicle maintenance expert. Based on the service history and the
owner's driving profile below, produce a forward-looking maintenance schedule:
the services that are coming up next and when they're due.

VEHICLE & SERVICE HISTORY (JSON):
$history

DRIVING PROFILE:
$profile

Use the driving profile to adjust intervals. For example: harsh braking,
hitting speed bumps hard, frequent overspeeding, or dusty/urban environments
shorten the life of brakes, suspension, tyres, and fluids, so bring those
services forward. Smooth driving extends them.

Return a maintenance schedule in this exact JSON shape:

{
  "items": [
    {
      "task": "short name of the service, e.g. Engine oil & filter change",
      "dueDate": "approximate due date or timeframe, e.g. 03/2026 or In 3 months",
      "dueOdometer": "approximate due mileage, e.g. ~205,000 km",
      "priority": "high | medium | low",
      "notes": "one short sentence on why, referencing the history or driving profile"
    }
  ]
}

Order items by priority (high first). Keep every field concise.

Return ONLY valid JSON, no markdown, no backticks, no explanation.''';

    final json = await _gemini.generateJson([
      {'text': prompt},
    ]);
    return MaintenanceSchedule.fromJson(json);
  }
}
