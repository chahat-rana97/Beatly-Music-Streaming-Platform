import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────

class SongQueue {
  final String id;
  String name;
  String icon;          // emoji or '' for default
  final List<String> songUris;

  SongQueue({
    required this.id,
    required this.name,
    String? icon,
    List<String>? songUris,
  })  : icon = icon ?? '',
        songUris = songUris ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'songUris': songUris,
  };

  factory SongQueue.fromJson(Map<String, dynamic> json) => SongQueue(
    id: json['id'] as String,
    name: json['name'] as String,
    // Graceful fallback for queues saved before this field existed
    icon: (json['icon'] as String?) ?? '',
    songUris: List<String>.from(json['songUris'] as List),
  );
}

// ─────────────────────────────────────────────
//  STORAGE SERVICE
// ─────────────────────────────────────────────

class QueueStorageService {
  static const _key = 'beatly_queues_v1';

  static Future<List<SongQueue>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => SongQueue.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<SongQueue> queues) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(queues.map((q) => q.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}