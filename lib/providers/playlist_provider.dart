import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Model
// ─────────────────────────────────────────────────────────────────────────────
class Playlist {
  final String id;
  String name;
  List<int> songIds; // stores on_audio_query song IDs
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'songIds': songIds,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
    id: j['id'] as String,
    name: j['name'] as String,
    songIds: List<int>.from(j['songIds'] as List),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  Playlist copyWith({String? name, List<int>? songIds}) => Playlist(
    id: id,
    name: name ?? this.name,
    songIds: songIds ?? List<int>.from(this.songIds),
    createdAt: createdAt,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Provider
// ─────────────────────────────────────────────────────────────────────────────
class PlaylistProvider extends ChangeNotifier {
  static const _key = 'beatly_playlists_v1';

  List<Playlist> _playlists = [];
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  PlaylistProvider() {
    _load();
  }

  // ── Persistence ──────────────────────────────────────────────────────────
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _playlists = list
            .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(_playlists.map((p) => p.toJson()).toList()));
    } catch (_) {}
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────
  Future<Playlist> createPlaylist(String name) async {
    final p = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'My Playlist' : name.trim(),
      songIds: [],
      createdAt: DateTime.now(),
    );
    _playlists.insert(0, p);
    notifyListeners();
    await _save();
    return p;
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final idx = _playlists.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _playlists[idx] = _playlists[idx].copyWith(name: newName.trim());
    notifyListeners();
    await _save();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> addSongToPlaylist(String playlistId, int songId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    final p = _playlists[idx];
    if (p.songIds.contains(songId)) return; // no dupes
    final updated = List<int>.from(p.songIds)..add(songId);
    _playlists[idx] = p.copyWith(songIds: updated);
    notifyListeners();
    await _save();
  }

  Future<void> removeSongFromPlaylist(String playlistId, int songId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    final p = _playlists[idx];
    final updated = List<int>.from(p.songIds)..remove(songId);
    _playlists[idx] = p.copyWith(songIds: updated);
    notifyListeners();
    await _save();
  }

  bool playlistContainsSong(String playlistId, int songId) {
    final p = _playlists.firstWhere((p) => p.id == playlistId,
        orElse: () => Playlist(
            id: '', name: '', songIds: [], createdAt: DateTime.now()));
    return p.songIds.contains(songId);
  }
}