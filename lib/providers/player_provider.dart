import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song_model.dart';

class PlayerProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();

  List<SongModel> songs = [];
  List<String> favouriteUris = [];
  int? currentIndex;

  bool isShuffling = false;
  LoopMode loopMode = LoopMode.off;

  ConcatenatingAudioSource? _playlist;

  PlayerProvider() {
    _loadFavourites();
    _handleCompletion();
    _listenCurrentIndex(); // ✅ ADD THIS

  }

  // ---------------- AUTO NEXT ON COMPLETE ----------------
  void _handleCompletion() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  void toggleShuffleAll() async {
    isShuffling = !isShuffling;

    await _player.setShuffleModeEnabled(isShuffling);

    if (isShuffling) {
      await _player.shuffle();
    }

    notifyListeners();
  }


  void _listenCurrentIndex() {
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < songs.length) {
        currentIndex = index;
        notifyListeners();
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
    currentIndex = index;

    if (_playlist == null) {
      _buildPlaylist();
    }

    await _player.setAudioSource(
      _playlist!,
      initialIndex: index,
    );

    // apply shuffle & repeat states
    await _player.setShuffleModeEnabled(isShuffling);
    if (isShuffling) {
      await _player.shuffle();
    }

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
  Future<void> toggleShuffle() async {
    isShuffling = !isShuffling;

    await _player.setShuffleModeEnabled(isShuffling);

    if (isShuffling) {
      await _player.shuffle();
    }

    notifyListeners();
  }

  void toggleRepeatOne() {
    loopMode = loopMode == LoopMode.one ? LoopMode.off : LoopMode.one;
    _player.setLoopMode(loopMode);
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
