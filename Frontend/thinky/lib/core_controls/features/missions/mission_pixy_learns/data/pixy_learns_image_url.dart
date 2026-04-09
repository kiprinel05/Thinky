import 'package:thinky/core_controls/config/app_config.dart';

/// Resolves image paths from the Pixy Learns API the same way as Word Match:
/// absolute `http(s)://`, bundled `assets/...`, `emoji:…` unchanged; otherwise API base + path.
class PixyLearnsImageUrl {
  PixyLearnsImageUrl._();

  static String resolve(String path) {
    final p = path.trim();
    if (p.isEmpty) return p;
    if (p.startsWith('emoji:')) return p;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('assets/')) return p;
    return '${AppConfig.apiBaseUrl}$p';
  }
}
