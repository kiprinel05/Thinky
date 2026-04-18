/// Native (Android / iOS / desktop) implementation of the local-file helpers.
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<Uint8List> readLocalFileBytes(String path) async {
  return File(path).readAsBytes();
}

String basenameOf(String path) {
  final sep = Platform.pathSeparator;
  final i = path.lastIndexOf(sep);
  if (i >= 0) return path.substring(i + 1);
  // Fallback for cases where the path uses the other separator.
  final j = path.lastIndexOf('/');
  return j >= 0 ? path.substring(j + 1) : path;
}

Future<String> tempFilePath(String filename) async {
  final dir = await getTemporaryDirectory();
  return '${dir.path}${Platform.pathSeparator}$filename';
}
