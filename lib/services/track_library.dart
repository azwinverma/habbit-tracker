import 'package:shared_preferences/shared_preferences.dart';

class MedTrack {
  final String title;
  final String url; // direct stream URL
  MedTrack(this.title, this.url);

  Map<String, String> toJson() => {'title': title, 'url': url};
  static MedTrack fromJson(Map j) => MedTrack(j['title'] as String, j['url'] as String);
}

class TrackLibrary {
  static const _key = 'meditation_tracks';

  static Future<List<MedTrack>> load() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key) ?? const [];
    return list.map((s) {
      final idx = s.indexOf('||');
      if (idx <= 0) return MedTrack(s, s);
      return MedTrack(s.substring(0, idx), s.substring(idx + 2));
    }).toList();
  }

  static Future<void> save(List<MedTrack> tracks) async {
    final p = await SharedPreferences.getInstance();
    final list = tracks.map((t) => '${t.title}||${t.url}').toList();
    await p.setStringList(_key, list);
  }

  static Future<void> add(MedTrack t) async {
    final items = await load();
    items.add(t);
    await save(items);
  }

  static Future<void> removeAt(int i) async {
    final items = await load();
    if (i >= 0 && i < items.length) {
      items.removeAt(i);
      await save(items);
    }
  }
}
