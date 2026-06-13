import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Native (desktop/mobile): hand the PDF to the OS share/print sheet.
Future<void> savePdf(Uint8List bytes, String filename) =>
    Printing.sharePdf(bytes: bytes, filename: filename);
