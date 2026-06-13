import 'dart:convert';
import 'dart:typed_data';

import '../models/service_record.dart';
import 'gemini_client.dart';

/// Sends a scanned maintenance document to Gemini and parses the response into
/// a [ServiceRecord].
class OcrService {
  final GeminiClient _gemini = GeminiClient();

  /// Instruction sent alongside the document image/PDF. Describes exactly the
  /// JSON shape we map back with [ServiceRecord.fromJson].
  static const _prompt = '''
You are an expert at reading vehicle maintenance and service receipts. The
document may be in English or Arabic, printed or handwritten.

Extract the vehicle's identity and its service history into this exact JSON
shape:

{
  "vehicle": {
    "makeModel": "make and model, e.g. Jeep Grand Cherokee 2011",
    "vin": "VIN or chassis number",
    "plate": "license plate",
    "customer": "customer name",
    "phone": "phone number"
  },
  "services": [
    {
      "date": "date of the visit",
      "odometer": "odometer / mileage reading at the visit",
      "workshop": "name of the workshop or service center",
      "workDone": ["one short string per job or part replaced"],
      "components": ["canonical IDs serviced in this visit, from the list below"]
    }
  ]
}

For "components", use ONLY these exact IDs, and include an ID only if that item
was actually serviced or replaced in that visit:
- "engine_oil"      -> engine oil change
- "oil_filter"      -> oil filter
- "air_filter"      -> air filter
- "shock_absorbers" -> shock absorbers / suspension dampers
- "brake_pads"      -> brake pads
- "coolant"         -> coolant / radiator fluid
- "tyre_rotation"   -> tyre rotation or tyre replacement
- "spark_plugs"     -> spark plugs

Rules:
- If a field is missing or unreadable, use an empty string "" (or [] for lists).
- Each receipt/page is usually one entry in "services". List them newest first.
- Keep each "workDone" item short (a part name or job), translated to English.

Return ONLY valid JSON, no markdown, no backticks, no explanation.''';

  /// Extracts a [ServiceRecord] from the raw bytes of the uploaded document.
  ///
  /// [mimeType] must match the file, e.g. `image/jpeg`, `image/png`,
  /// `image/heic`, or `application/pdf`.
  Future<ServiceRecord> analyze(
    Uint8List bytes, {
    required String mimeType,
  }) async {
    final json = await _gemini.generateJson([
      {'text': _prompt},
      {
        'inline_data': {
          'mime_type': mimeType,
          'data': base64Encode(bytes),
        },
      },
    ]);
    return ServiceRecord.fromJson(json);
  }
}
