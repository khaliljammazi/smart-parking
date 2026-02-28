// Conditional export: web implementation uses dart:html, mobile uses stub
export 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';
