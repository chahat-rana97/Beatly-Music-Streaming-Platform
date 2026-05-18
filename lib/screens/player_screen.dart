import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────────────────────
class _P {
  static const Color bg          = Color(0xFF06060E);
  static const Color surface     = Color(0xFF0E0E1A);
  static const Color surfaceMid  = Color(0xFF141420);
  static const Color surfaceHigh = Color(0xFF1C1C2E);
  static const Color border      = Color(0xFF242436);

  static const Color red      = Color(0xFFFF3B3B);
  static const Color redDeep  = Color(0xFFAA1A1A);
  static const Color redSoft  = Color(0x22FF3B3B);
  static const Color redGlow  = Color(0x55FF3B3B);
  static const Color redBorder= Color(0x77FF3B3B);

  static const Color textPrimary   = Color(0xFFF0F0F8);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted     = Color(0xFF44445A);
}

// ─────────────────────────────────────────────────────────────────────────────
//  PlayerScreen
// ─────────────────────────────────────────────────────────────────────────────
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  StreamSubscription<PlayerState>? _playerSub;

  // Song info slide/fade
  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  // Waveform
  late AnimationController _waveCtrl;
  final List<double> _barHeights = [];
  final Random _rng = Random();
  static const int _barCount = 38;

  // Ambient glow
  late AnimationController _glowCtrl;
  late Animation<double>   _glowAnim;

  // Entrance animation
  late AnimationController _entranceCtrl;
  late Animation<double>   _entranceFade;
  late Animation<Offset>   _entranceSlide;

  Timer?    _sleepTicker;
  Duration? _remainingSleep;

  String? _lastSongUri;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < _barCount; i++) {
      _barHeights.add(0.12 + _rng.nextDouble() * 0.88);
    }

    // Entrance
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entranceFade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));
    _entranceSlide = Tween<Offset>(
        begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _entranceCtrl.forward();

    // Ambient glow
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Song slide/fade
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();

    // Waveform
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100))
      ..addListener(() {
        if (_isPlaying && mounted) {
          setState(() {
            for (int i = 0; i < _barCount; i++) {
              _barHeights[i] = 0.08 + _rng.nextDouble() * 0.92;
            }
          });
        }
      });

    // Player state
    final player = Provider.of<PlayerProvider>(context, listen: false).audioPlayer;
    _playerSub = player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
      if (state.playing) {
        if (!_glowCtrl.isAnimating) _glowCtrl.repeat(reverse: true);
        _waveCtrl.repeat();
      } else {
        _glowCtrl.stop();
        _waveCtrl.stop();
        setState(() {
          for (int i = 0; i < _barCount; i++) {
            _barHeights[i] = 0.08 + _rng.nextDouble() * 0.18;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sleepTicker?.cancel();
    _playerSub?.cancel();
    _slideCtrl.dispose();
    _waveCtrl.dispose();
    _glowCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _triggerSongTransition() {
    _slideCtrl.reset();
    _slideCtrl.forward();
  }

  // ───────────────────────── BUILD ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context);
    final player   = provider.audioPlayer;
    final song     = provider.currentIndex != null
        ? provider.songs[provider.currentIndex!]
        : null;

    if (song?.uri != _lastSongUri) {
      _lastSongUri = song?.uri;
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerSongTransition());
    }

    final isFav = song != null && provider.favouriteUris.contains(song.uri);

    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          _buildAmbientBg(),
          FadeTransition(
            opacity: _entranceFade,
            child: SlideTransition(
              position: _entranceSlide,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildAlbumArt(song),
                          const SizedBox(height: 12),
                          _buildWaveform(),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: _buildSongInfo(song, isFav, provider),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildSeekBar(player),
                          const SizedBox(height: 22),
                          _buildControls(provider, player),
                          if (_remainingSleep != null) ...[
                            const SizedBox(height: 14),
                            _buildSleepDisplay(),
                          ],
                          const Spacer(),
                          _buildBottomBar(context, provider),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── AMBIENT BACKGROUND ─────────────
  Widget _buildAmbientBg() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Stack(
        children: [
          Container(color: _P.bg),
          Positioned(
            top: -60, left: 0, right: 0,
            child: Center(
              child: _GlowBlob(
                size: 380,
                color: _P.redDeep.withOpacity(0.30 * _glowAnim.value),
                blur: 90,
              ),
            ),
          ),
          Positioned(
            bottom: -40, left: 0, right: 0,
            child: Center(
              child: _GlowBlob(
                size: 300,
                color: _P.redDeep.withOpacity(0.18 * _glowAnim.value),
                blur: 80,
              ),
            ),
          ),
          Positioned(
            top: 300, right: -80,
            child: _GlowBlob(
              size: 200,
              color: _P.red.withOpacity(0.08 * _glowAnim.value),
              blur: 60,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x28FF3B3B), Colors.transparent, Color(0x10FF3B3B)],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── TOP BAR ─────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _IconTap(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: () => Navigator.pop(context),
            size: 42,
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                'NOW PLAYING',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _P.textMuted,
                  letterSpacing: 3.0,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Beatly',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _P.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 42), // balance
        ],
      ),
    );
  }

  // ───────────── ALBUM ART ─────────────
  Widget _buildAlbumArt(song) {
    final screenW = MediaQuery.of(context).size.width;
    final size    = screenW - 56.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow halo
            Container(
              width: size + 28,
              height: size + 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: RadialGradient(
                  colors: [
                    _P.red.withOpacity(0.18 * _glowAnim.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Main art card
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _P.redBorder.withOpacity(0.6 + 0.4 * _glowAnim.value),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _P.red.withOpacity(0.20 * _glowAnim.value),
                    blurRadius: 32,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                color: _P.surfaceMid,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: song != null
                    ? QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkWidth: size,
                  artworkHeight: size,
                  artworkFit: BoxFit.cover,
                  artworkBorder: BorderRadius.zero,
                  keepOldArtwork: true,
                  nullArtworkWidget: _artFallback(size),
                )
                    : _artFallback(size),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artFallback(double size) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1A0808), Color(0xFF2A0E0E), Color(0xFF160606)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Image.asset(
        'assets/icon/beatlyicon.png',
        width: size * 0.42,
        height: size * 0.42,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.music_note_rounded,
          size: size * 0.28,
          color: _P.red.withOpacity(0.45),
        ),
      ),
    ),
  );

  // ───────────── WAVEFORM ─────────────
  Widget _buildWaveform() {
    const maxH = 32.0;
    const minH = 2.5;

    return SizedBox(
      height: maxH + 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_barCount, (i) {
            final t  = _barHeights[i];
            final h  = _isPlaying
                ? (minH + t * (maxH - minH))
                : (minH + t * 7.0);
            final center = _barCount / 2;
            final dist   = (i - center).abs() / center;
            final op     = _isPlaying
                ? (0.22 + (1 - dist) * 0.78).clamp(0.0, 1.0)
                : 0.13;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 95),
              curve: Curves.easeOut,
              width: 2.2,
              height: h,
              decoration: BoxDecoration(
                color: _P.red.withOpacity(op),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ───────────── SONG INFO ─────────────
  Widget _buildSongInfo(song, bool isFav, PlayerProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song?.title ?? 'No song selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _P.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  song?.artist ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _P.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: song == null ? null : () => provider.toggleFavourite(song.uri),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: isFav ? _P.redSoft : _P.surfaceHigh,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isFav ? _P.redBorder : _P.border,
                  width: 0.8,
                ),
                boxShadow: isFav
                    ? [BoxShadow(color: _P.red.withOpacity(0.25), blurRadius: 14)]
                    : [],
              ),
              child: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? _P.red : _P.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── SEEK BAR ─────────────
  Widget _buildSeekBar(player) {
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, dSnap) {
        final total = dSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, pSnap) {
            final pos = pSnap.data ?? Duration.zero;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _P.red,
                      inactiveTrackColor: _P.surfaceHigh,
                      thumbColor: Colors.white,
                      overlayColor: _P.redGlow,
                      trackHeight: 3.2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 13),
                    ),
                    child: Slider(
                      value: min(pos.inMilliseconds.toDouble(),
                          total.inMilliseconds.toDouble()),
                      max: total.inMilliseconds > 0
                          ? total.inMilliseconds.toDouble()
                          : 1.0,
                      onChanged: (v) =>
                          player.seek(Duration(milliseconds: v.toInt())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(pos),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _P.textSecondary, fontSize: 11)),
                        Text(_fmt(total),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _P.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ───────────── CONTROLS ─────────────
  Widget _buildControls(PlayerProvider provider, player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SmallCtrl(
            icon: Icons.shuffle_rounded,
            isActive: provider.isShuffling,
            onTap: provider.toggleShuffle,
          ),
          _NavBtn(icon: Icons.skip_previous_rounded, onTap: provider.playPrevious),
          // Play/Pause centrepiece
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (_, snap) {
              final playing = snap.data?.playing ?? false;
              return GestureDetector(
                onTap: () => playing ? provider.pause() : provider.resume(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4B4B), Color(0xFFAA1414)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _P.red.withOpacity(playing ? 0.60 : 0.28),
                        blurRadius: playing ? 36 : 14,
                        offset: const Offset(0, 8),
                        spreadRadius: playing ? 3 : 0,
                      ),
                    ],
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ]),
                ),
              );
            },
          ),
          _NavBtn(icon: Icons.skip_next_rounded, onTap: provider.playNext),
          _SmallCtrl(
            icon: provider.loopMode == LoopMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            isActive: provider.loopMode != LoopMode.off,
            onTap: provider.toggleRepeatOne,
          ),
        ],
      ),
    );
  }

  // ───────────── BOTTOM BAR (Sleep + Queue) ─────────────
  Widget _buildBottomBar(BuildContext context, PlayerProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Sleep timer pill
          Expanded(
            child: GestureDetector(
              onTap: () => _openSleepTimer(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 50,
                decoration: BoxDecoration(
                  color: _remainingSleep != null ? _P.redSoft : _P.surfaceMid,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: _remainingSleep != null ? _P.redBorder : _P.border,
                    width: 0.8,
                  ),
                  boxShadow: _remainingSleep != null
                      ? [BoxShadow(color: _P.red.withOpacity(0.2), blurRadius: 14)]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: _remainingSleep != null ? _P.red : _P.textSecondary,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _remainingSleep != null
                          ? '${_remainingSleep!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_remainingSleep!.inSeconds.remainder(60).toString().padLeft(2, '0')}'
                          : 'Sleep',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _remainingSleep != null ? _P.red : _P.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Queue pill
          Expanded(
            child: GestureDetector(
              onTap: () => _openQueue(context),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _P.surfaceMid,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: _P.border, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.queue_music_rounded,
                      color: _P.textSecondary,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Queue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _P.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── SLEEP DISPLAY (inline) ─────────────
  Widget _buildSleepDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        color: _P.redSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _P.redBorder, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: _P.red, size: 15),
          const SizedBox(width: 8),
          Text(
            'Stops in  ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _P.textSecondary, fontSize: 12,
            ),
          ),
          Text(
            '${_remainingSleep!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_remainingSleep!.inSeconds.remainder(60).toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _P.red,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── BOTTOM SHEETS ─────────────
  void _openSleepTimer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _P.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          _sheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sleep Timer',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _P.textPrimary, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _timerOption(const Duration(minutes: 15)),
          _timerOption(const Duration(minutes: 30)),
          _timerOption(const Duration(hours: 1)),
          if (_remainingSleep != null)
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: _P.red),
              title: Text(
                'Cancel timer',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _P.red),
              ),
              onTap: _cancelSleepTimer,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _timerOption(Duration duration) {
    final label = duration.inMinutes >= 60 ? '1 hour' : '${duration.inMinutes} minutes';
    return ListTile(
      leading: const Icon(Icons.timer_outlined, color: _P.textSecondary),
      title: Text(label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _P.textPrimary)),
      onTap: () {
        Navigator.pop(context);
        _startSleepTimer(duration);
      },
    );
  }

  void _startSleepTimer(Duration duration) {
    _sleepTicker?.cancel();
    setState(() => _remainingSleep = duration);
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSleep == null) return;
      if (_remainingSleep!.inSeconds <= 1) {
        Provider.of<PlayerProvider>(context, listen: false).pause();
        _cancelSleepTimer();
      } else {
        setState(() =>
        _remainingSleep = Duration(seconds: _remainingSleep!.inSeconds - 1));
      }
    });
  }

  void _cancelSleepTimer() {
    _sleepTicker?.cancel();
    setState(() => _remainingSleep = null);
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _openQueue(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: _P.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 10),
            _sheetHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Up Next',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _P.textPrimary, fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _P.redSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${provider.songs.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _P.red, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: provider.songs.length,
                itemBuilder: (context, index) {
                  final s       = provider.songs[index];
                  final current = index == provider.currentIndex;
                  return ListTile(
                    onTap: () {
                      provider.playSongAtIndex(index);
                      Navigator.pop(context);
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: QueryArtworkWidget(
                        id: s.id,
                        type: ArtworkType.AUDIO,
                        artworkWidth: 44,
                        artworkHeight: 44,
                        artworkFit: BoxFit.cover,
                        artworkBorder: BorderRadius.zero,
                        keepOldArtwork: true,
                        nullArtworkWidget: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: current ? _P.redSoft : _P.surfaceMid,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            current ? Icons.equalizer_rounded : Icons.music_note_rounded,
                            color: current ? _P.red : _P.textSecondary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: current ? FontWeight.w600 : FontWeight.w500,
                        color: current ? _P.red : _P.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      s.artist,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _P.textSecondary,
                      ),
                    ),
                    trailing: current
                        ? Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _P.redSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.equalizer_rounded, color: _P.red, size: 16),
                    )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── HELPERS ─────────────
  Widget _sheetHandle() => Container(
    width: 36, height: 4,
    decoration: BoxDecoration(
      color: _P.surfaceHigh,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _IconTap extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _IconTap({required this.icon, required this.onTap, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: _P.surfaceMid,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _P.border, width: 0.8),
        ),
        child: Icon(icon, color: _P.textSecondary, size: 22),
      ),
    );
  }
}

class _SmallCtrl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _SmallCtrl({required this.icon, required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: isActive ? _P.redSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: isActive ? _P.red : _P.textMuted, size: 22),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _NavBtn({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: _P.surfaceMid,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: _P.textPrimary, size: 26),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color  color;
  final double blur;

  const _GlowBlob({required this.size, required this.color, this.blur = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: const SizedBox.expand(),
      ),
    );
  }
}