import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song_model.dart';

const _kKeyShuffle = 'pref_shuffle';
const _kKeyLoop    = 'pref_loop'; // 0=off, 1=all, 2=one

class PlayerProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();

  List<SongModel> songs = [];
  List<String> favouriteUris = [];
  int? currentIndex;

  bool isShuffling = false;
  LoopMode loopMode = LoopMode.off;

  ConcatenatingAudioSource? _playlist;

  bool _hasStartedPlaying = false;

  PlayerProvider() {
    _loadFavourites();
    _loadPlaybackPrefs();
    _handleCompletion();
    _listenCurrentIndex();
  }

  // ---------------- PERSIST / LOAD PREFS ----------------
  Future<void> _loadPlaybackPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isShuffling = prefs.getBool(_kKeyShuffle) ?? false;
    final loopIndex = prefs.getInt(_kKeyLoop) ?? 0;
    loopMode = LoopMode.values[loopIndex.clamp(0, LoopMode.values.length - 1)];

    await _player.setShuffleModeEnabled(isShuffling);
    await _player.setLoopMode(loopMode);
    notifyListeners();
  }

  Future<void> _saveShufflePref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKeyShuffle, isShuffling);
  }

  Future<void> _saveLoopPref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kKeyLoop, loopMode.index);
  }

  // ---------------- AUTO NEXT ON COMPLETE ----------------
  void _handleCompletion() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  void _listenCurrentIndex() {
    _player.currentIndexStream.listen((index) {
      if (!_hasStartedPlaying) return;
      if (index == null) return;

      final seq = _player.sequence;
      if (seq != null && index >= 0 && index < seq.length) {
        final tag = seq[index].tag as MediaItem?;
        if (tag != null) {
          final id = int.tryParse(tag.id);
          if (id != null) {
            final found = songs.indexWhere((s) => s.id == id);
            if (found != -1) {
              currentIndex = found;
              notifyListeners();
            }
          }
        }
      }
    });
  }

  // ---------------- PERMISSION ----------------
  Future<bool> _requestPermission() async {
    if (await Permission.audio.request().isGranted) return true;
    if (await Permission.storage.request().isGranted) return true;
    await Permission.notification.request();
    return false;
  }

  // ---------------- LOAD SONGS ----------------
  Future<void> loadSongs() async {
    if (!await _requestPermission()) return;

    final audios = await _audioQuery.querySongs(
      uriType: UriType.EXTERNAL,
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      ignoreCase: true,
    );

    songs = audios
        .map(
          (a) => SongModel(
        id: a.id,
        title: a.title,
        artist: a.artist ?? "Unknown",
        uri: a.data,
      ),
    )
        .toList();

    _buildPlaylist();
    notifyListeners();
  }

  // ---------------- PLAYLIST ----------------
  void _buildPlaylist() {
    _playlist = ConcatenatingAudioSource(
      children: songs
          .map(
            (s) => AudioSource.uri(
          Uri.parse(s.uri),
          tag: MediaItem(
            id: s.id.toString(),
            album: "Local Music",
            title: s.title,
            artist: s.artist,
            artUri: Uri.parse(
                "content://media/external/audio/albumart/${s.id}"),
          ),
        ),
      )
          .toList(),
    );
  }

  // ---------------- FAVORITES ----------------
  Future<void> _loadFavourites() async {
    final sp = await SharedPreferences.getInstance();
    favouriteUris = sp.getStringList("favs") ?? [];
    notifyListeners();
  }

  Future<void> toggleFavourite(String uri) async {
    final sp = await SharedPreferences.getInstance();
    if (favouriteUris.contains(uri)) {
      favouriteUris.remove(uri);
    } else {
      favouriteUris.add(uri);
    }
    await sp.setStringList("favs", favouriteUris);
    notifyListeners();
  }

  // ---------------- PLAYBACK ----------------
  Future<void> playSongAtIndex(int index) async {
    if (index < 0 || index >= songs.length) return;

    _hasStartedPlaying = true;
    currentIndex = index;

    if (_playlist == null) _buildPlaylist();

    await _player.setAudioSource(
      _playlist!,
      initialIndex: index,
    );

    await _player.setShuffleModeEnabled(isShuffling);
    if (isShuffling) await _player.shuffle();
    await _player.setLoopMode(loopMode);

    _player.play();
    notifyListeners();
  }

  Future<void> playQueueAtIndex(List<String> queueUris, int indexInQueue) async {
    if (indexInQueue < 0 || indexInQueue >= queueUris.length) return;

    final queueSongs = queueUris
        .map((uri) => songs.firstWhere((s) => s.uri == uri,
        orElse: () => songs.first))
        .where((s) => queueUris.contains(s.uri))
        .toList();

    if (queueSongs.isEmpty) return;

    _hasStartedPlaying = true;
    currentIndex = songs.indexOf(queueSongs[indexInQueue]);

    final subPlaylist = ConcatenatingAudioSource(
      children: queueSongs
          .map((s) => AudioSource.uri(
        Uri.parse(s.uri),
        tag: MediaItem(
          id: s.id.toString(),
          album: "Local Music",
          title: s.title,
          artist: s.artist,
          artUri: Uri.parse(
              "content://media/external/audio/albumart/${s.id}"),
        ),
      ))
          .toList(),
    );

    await _player.setAudioSource(subPlaylist, initialIndex: indexInQueue);
    await _player.setShuffleModeEnabled(isShuffling);
    if (isShuffling) await _player.shuffle();
    await _player.setLoopMode(loopMode);
    _player.play();
    notifyListeners();
  }

  void pause() {
    _player.pause();
    notifyListeners();
  }

  void resume() {
    _player.play();
    notifyListeners();
  }

  void stop() {
    _player.stop();
    notifyListeners();
  }

  // ---------------- SHUFFLE + REPEAT ----------------

  /// Used by the player screen's shuffle button (toggles current session only)
  Future<void> toggleShuffle() async {
    isShuffling = !isShuffling;
    await _player.setShuffleModeEnabled(isShuffling);
    if (isShuffling) await _player.shuffle();
    await _saveShufflePref();
    notifyListeners();
  }

  /// Used by the home screen's shuffle button (same behaviour, same persist)
  Future<void> toggleShuffleAll() async {
    isShuffling = !isShuffling;
    await _player.setShuffleModeEnabled(isShuffling);
    if (isShuffling) await _player.shuffle();
    await _saveShufflePref();
    notifyListeners();
  }

  Future<void> toggleRepeatOne() async {
    loopMode = loopMode == LoopMode.one ? LoopMode.off : LoopMode.one;
    await _player.setLoopMode(loopMode);
    await _saveLoopPref();
    notifyListeners();
  }

  // ---------------- NEXT / PREVIOUS ----------------
  Future<void> playNext() async {
    if (!_player.hasNext) return;
    await _player.seekToNext();
    currentIndex = _player.currentIndex;
    notifyListeners();
  }

  Future<void> playPrevious() async {
    if (!_player.hasPrevious) return;
    await _player.seekToPrevious();
    currentIndex = _player.currentIndex;
    notifyListeners();
  }

  // ---------------- STREAMS ----------------
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  AudioPlayer get audioPlayer => _player;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}