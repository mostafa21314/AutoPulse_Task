/// The owner's driving characteristics, collected as explicit choices on the
/// results screen and used to adjust maintenance intervals per component.
///
/// Each field is a binary choice; `false` is the gentler option.
class DrivingProfile {
  /// true = frequently overspeeds (high RPM / heat); false = normal speeds.
  final bool overspeeding;

  /// true = off-road / rough terrain; false = urban environment.
  final bool offRoad;

  /// true = sudden / hard braking; false = smooth braking.
  final bool suddenBraking;

  const DrivingProfile({
    required this.overspeeding,
    required this.offRoad,
    required this.suddenBraking,
  });

  /// Human-readable one-liner — shown in the PDF and fed to the Gemini summary.
  String describe() =>
      '${overspeeding ? 'Frequent overspeeding (high RPM)' : 'Normal speeds'}. '
      '${offRoad ? 'Off-road / rough terrain' : 'Urban environment'}. '
      '${suddenBraking ? 'Sudden, hard braking' : 'Smooth braking'}.';
}
