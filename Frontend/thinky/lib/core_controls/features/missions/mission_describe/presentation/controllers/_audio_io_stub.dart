/// Stub used on web — file-system reads aren't possible there. The controller
/// switches to fetching the recording's blob URL via `http.get` instead and
/// never calls these helpers, so we just throw if anyone tries.
import 'dart:typed_data';

Future<Uint8List> readLocalFileBytes(String path) {
  throw UnsupportedError('readLocalFileBytes is not supported on web.');
}

String basenameOf(String path) {
  final i = path.lastIndexOf('/');
  return i >= 0 ? path.substring(i + 1) : path;
}

Future<String> tempFilePath(String filename) {
  throw UnsupportedError('tempFilePath is not supported on web.');
}
