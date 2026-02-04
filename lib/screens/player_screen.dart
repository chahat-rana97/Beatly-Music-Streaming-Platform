import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

import '../providers/player_provider.dart';
import '../utils/beatly_messages.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  StreamSubscription<PlayerState>? _playerSub;

  Timer? _sleepTicker;
  Duration? _remainingSleep;

  Timer? _messageTimer;
  String _currentMessage = BeatlyMessages.random();

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );

    final player =
        Provider.of<PlayerProvider>(context, listen: false).audioPlayer;

    _playerSub = player.playerStateStream.listen((state) {
      if (state.playing) {
        if (!_rotationController.isAnimating) {
          _rotationController.repeat();
        }
      } else {
        _rotationController.stop();
      }
    });

    // Random Beatly messages
    _messageTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_remainingSleep == null) {
        setState(() {
          _currentMessage =
              BeatlyMessages.random(exclude: _currentMessage);
        });
      }
    });
  }

  @override
  void dispose() {
    _sleepTicker?.cancel();
    _messageTimer?.cancel();
    _playerSub?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context);
    final player = provider.audioPlayer;

    final song = provider.currentIndex != null
        ? provider.songs[provider.currentIndex!]
        : null;

    final isFav =
        song != null && provider.favouriteUris.contains(song.uri);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.timer,
              color: _remainingSleep != null
                  ? Colors.tealAccent
                  : Colors.white,
            ),
            onPressed: () => _openSleepTimer(context),
          ),
          IconButton(
            icon: const Icon(Icons.lyrics, color: Colors.white),
            onPressed: () => _openLyrics(context),
          ),
          IconButton(
            icon: const Icon(Icons.queue_music, color: Colors.white),
            onPressed: () => _openQueue(context),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F2C34),
                Color(0xFF1F4E5F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2C34),
              Color(0xFF1F4E5F),
              Color(0xFF0F2C34),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                "Beatly • Feel the Beat",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 26),

              // 💿 DISC WITH GESTURES
              if (song != null)
                GestureDetector(
                  onDoubleTap: () =>
                  player.playing ? provider.pause() : provider.resume(),
                  onHorizontalDragEnd: (d) {
                    if (d.primaryVelocity == null) return;
                    if (d.primaryVelocity! < -300) {
                      provider.playNext();
                    } else if (d.primaryVelocity! > 300) {
                      provider.playPrevious();
                    }
                  },
                  child: RotationTransition(
                    turns: _rotationController,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 280,
                          width: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFF1E3C44),
                                Color(0xFF0F2C34),
                                Colors.black,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.7),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 200,
                          width: 200,
                          decoration:
                          const BoxDecoration(shape: BoxShape.circle),
                          child: ClipOval(
                            child: Image(
                              image: NetworkImage(
                                "content://media/external/audio/albumart/${song.id}",
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.music_note,
                                  size: 70,
                                  color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              Text(song?.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Text(song?.artist ?? '',
                  style: const TextStyle(
                      fontSize: 15, color: Colors.white70)),

              const SizedBox(height: 16),

              // ─── SEEK BAR ───
              StreamBuilder<Duration?>(
                stream: player.durationStream,
                builder: (context, snap) {
                  final total = snap.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, snapshot) {
                      final pos = snapshot.data ?? Duration.zero;
                      return Column(
                        children: [
                          Slider(
                            activeColor: Colors.white,
                            inactiveColor: Colors.white30,
                            value: min(
                              pos.inMilliseconds.toDouble(),
                              total.inMilliseconds.toDouble(),
                            ),
                            max: total.inMilliseconds.toDouble(),
                            onChanged: (v) => player.seek(
                                Duration(milliseconds: v.toInt())),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                _timeText(pos),
                                _timeText(total),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // ─── CONTROLS (REPEAT ADDED) ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔁 REPEAT
                  IconButton(
                    icon: Icon(
                      provider.loopMode == LoopMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                    ),
                    color: provider.loopMode != LoopMode.off
                        ? Colors.tealAccent
                        : Colors.white70,
                    onPressed: provider.toggleRepeatOne,
                  ),

                  // 🔀 SHUFFLE
                  IconButton(
                    icon: const Icon(Icons.shuffle),
                    color: provider.isShuffling
                        ? Colors.tealAccent
                        : Colors.white70,
                    onPressed: provider.toggleShuffle,
                  ),

                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.skip_previous),
                    color: Colors.white,
                    onPressed: provider.playPrevious,
                  ),

                  StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (_, snap) {
                      final playing = snap.data?.playing ?? false;
                      return IconButton(
                        iconSize: 72,
                        icon: Icon(playing
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled),
                        color: Colors.white,
                        onPressed: () =>
                        playing ? provider.pause() : provider.resume(),
                      );
                    },
                  ),

                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.skip_next),
                    color: Colors.white,
                    onPressed: provider.playNext,
                  ),



                  IconButton(
                    icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border),
                    color:
                    isFav ? Colors.redAccent : Colors.white70,
                    onPressed: song == null
                        ? null
                        : () => provider.toggleFavourite(song.uri),
                  ),
                ],
              ),

              // ─── TIMER / MESSAGES ───
              if (_remainingSleep != null)
                Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      "Your beats will stop in",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _timeBox(
                            _remainingSleep!.inMinutes.remainder(60)),
                        const Text(" : ",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 18)),
                        _timeBox(
                            _remainingSleep!.inSeconds.remainder(60)),
                      ],
                    ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      _currentMessage,
                      key: ValueKey(_currentMessage),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SLEEP TIMER ───
  void _openSleepTimer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _timerOption(const Duration(minutes: 15)),
          _timerOption(const Duration(minutes: 30)),
          _timerOption(const Duration(hours: 1)),
          if (_remainingSleep != null)
            ListTile(
              title: const Text('Cancel timer',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: _cancelSleepTimer,
            ),
        ],
      ),
    );
  }

  Widget _timerOption(Duration duration) {
    final label = duration.inMinutes >= 60
        ? '1 hour'
        : '${duration.inMinutes} minutes';

    return ListTile(
      title:
      Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        _startSleepTimer(duration);
      },
    );
  }

  void _startSleepTimer(Duration duration) {
    _sleepTicker?.cancel();
    setState(() => _remainingSleep = duration);

    _sleepTicker =
        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_remainingSleep == null) return;

          if (_remainingSleep!.inSeconds <= 1) {
            Provider.of<PlayerProvider>(context, listen: false)
                .pause();
            _cancelSleepTimer();
          } else {
            setState(() {
              _remainingSleep =
                  Duration(seconds: _remainingSleep!.inSeconds - 1);
            });
          }
        });
  }

  void _cancelSleepTimer() {
    _sleepTicker?.cancel();
    setState(() => _remainingSleep = null);
    Navigator.pop(context);
  }

  // ─── MISC ───
  void _openLyrics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Lyrics will be available soon 🎶',
              style:
              TextStyle(color: Colors.white70, fontSize: 16)),
        ),
      ),
    );
  }

  void _openQueue(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ListView.builder(
        itemCount: provider.songs.length,
        itemBuilder: (context, index) {
          final s = provider.songs[index];
          final current = index == provider.currentIndex;
          return ListTile(
            onTap: () {
              provider.playSongAtIndex(index);
              Navigator.pop(context);
            },
            leading: Icon(
              current
                  ? Icons.play_circle_fill
                  : Icons.music_note,
              color:
              current ? Colors.tealAccent : Colors.white70,
            ),
            title: Text(
              s.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: current
                      ? Colors.tealAccent
                      : Colors.white),
            ),
            subtitle: Text(s.artist,
                style:
                const TextStyle(color: Colors.white60)),
          );
        },
      ),
    );
  }

  Widget _timeText(Duration d) {
    final m =
    d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s =
    d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text('$m:$s',
        style:
        const TextStyle(color: Colors.white70, fontSize: 13));
  }

  Widget _timeBox(int value) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value.toString().padLeft(2, '0'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
