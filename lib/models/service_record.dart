// Data models for a maintenance record extracted from a scanned document.
//
// These mirror the shape we expect the OCR step (see `OcrService`) to return.
// For now they're populated with placeholder data via `ServiceRecord.sample`
// so the results screen can be built independently of the API.

/// Who the vehicle belongs to and how to identify it — the header block that
/// appears at the top of most service receipts.
class VehicleIdentity {
  final String makeModel;
  final String vin; // VIN / chassis number
  final String plate;
  final String customer;
  final String phone;

  const VehicleIdentity({
    required this.makeModel,
    required this.vin,
    required this.plate,
    required this.customer,
    required this.phone,
  });

  factory VehicleIdentity.fromJson(Map<String, dynamic> json) {
    return VehicleIdentity(
      makeModel: json['makeModel'] as String? ?? '',
      vin: json['vin'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      customer: json['customer'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'makeModel': makeModel,
        'vin': vin,
        'plate': plate,
        'customer': customer,
        'phone': phone,
      };
}

/// A single visit to a workshop — one row in the service-history table.
///
/// [workDone] is a list because a visit usually covers several jobs (oil
/// change, brake pads, coolant flush, …), each its own line on the receipt.
class ServiceInstant {
  final String date;
  final String odometer; // mileage reading at the time of service
  final String workshop;
  final List<String> workDone;

  /// Canonical maintenance-component IDs serviced in this visit, tagged by
  /// Gemini (see `MaintenanceModel.components`). Used to cross-validate when
  /// each tracked job was last done. Empty for manually-added rows.
  final List<String> components;

  const ServiceInstant({
    required this.date,
    required this.odometer,
    required this.workshop,
    required this.workDone,
    this.components = const [],
  });

  factory ServiceInstant.fromJson(Map<String, dynamic> json) {
    return ServiceInstant(
      date: json['date'] as String? ?? '',
      odometer: json['odometer'] as String? ?? '',
      workshop: json['workshop'] as String? ?? '',
      workDone: (json['workDone'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      components: (json['components'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'odometer': odometer,
        'workshop': workshop,
        'workDone': workDone,
        'components': components,
      };
}

/// The full result of analyzing a document: the vehicle it belongs to plus
/// every service visit we could read from it.
class ServiceRecord {
  final VehicleIdentity vehicle;
  final List<ServiceInstant> services;

  const ServiceRecord({required this.vehicle, required this.services});

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRecord(
      vehicle: VehicleIdentity.fromJson(
        json['vehicle'] as Map<String, dynamic>? ?? const {},
      ),
      services: (json['services'] as List<dynamic>? ?? const [])
          .map((e) => ServiceInstant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicle': vehicle.toJson(),
        'services': services.map((s) => s.toJson()).toList(),
      };

  /// Placeholder data used while the OCR pipeline is being wired up.
  /// Modelled on the sample "Jeep Full Service History" document.
  factory ServiceRecord.sample() {
    return const ServiceRecord(
      vehicle: VehicleIdentity(
        makeModel: 'Jeep Grand Cherokee 2011',
        vin: '1C4RJFBT4CC211983',
        plate: 'ا ع ف 8472',
        customer: 'يوسف محمود',
        phone: '01120777237',
      ),
      services: [
        ServiceInstant(
          date: '23/08/2025',
          odometer: '196,772 km',
          workshop: 'Mopars Garage',
          workDone: [
            'Front shock absorber',
            'Lower ball joints',
            'Bump stop',
            'Coil springs',
          ],
          components: ['shock_absorbers'],
        ),
        ServiceInstant(
          date: '19/03/2025',
          odometer: '188,974 km',
          workshop: 'Mopars Garage',
          workDone: [
            'Manifold gasket replacement',
            'Oil seal',
            'Hex flange bolts',
          ],
          components: [],
        ),
        ServiceInstant(
          date: '17/02/2025',
          odometer: '187,011 km',
          workshop: 'Mopars Garage',
          workDone: [
            'Coolant flush (10 L)',
            'Cooling system service',
          ],
          components: ['coolant'],
        ),
        ServiceInstant(
          date: '21/12/2024',
          odometer: '185,390 km',
          workshop: 'Mopars Garage',
          workDone: [
            'Engine oil & filter change',
            'Hood lift support',
            'Oil pressure switch',
          ],
          components: ['engine_oil', 'oil_filter'],
        ),
      ],
    );
  }
}
