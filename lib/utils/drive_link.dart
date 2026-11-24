class DriveLink {
  // Accepts any common Google Drive share link and returns a direct stream URL.
  // Examples accepted:
  // https://drive.google.com/file/d/FILE_ID/view?usp=sharing
  // https://drive.google.com/open?id=FILE_ID
  // https://drive.google.com/uc?export=download&id=FILE_ID
  // https://drive.google.com/uc?id=FILE_ID
  static String? toDirect(String raw) {
    final url = raw.trim();
    final patterns = <RegExp>[
      RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/'),
      RegExp(r'drive\.google\.com/open\?id=([a-zA-Z0-9_-]+)'),
      RegExp(r'drive\.google\.com/uc\?.*?[&?]id=([a-zA-Z0-9_-]+)'),
      RegExp(r'drive\.google\.com/uc\?id=([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null && m.groupCount >= 1) {
        final id = m.group(1)!;
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
    }
    // Also accept the raw file id:
    if (RegExp(r'^[a-zA-Z0-9_-]{20,}$').hasMatch(url)) {
      return 'https://drive.google.com/uc?export=download&id=$url';
    }
    return null;
  }
}
