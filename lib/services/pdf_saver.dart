// Saves PDF bytes to the device. The implementation is platform-specific:
// a direct browser download on web, and the share/print sheet elsewhere.
export 'pdf_saver_io.dart' if (dart.library.html) 'pdf_saver_web.dart';
