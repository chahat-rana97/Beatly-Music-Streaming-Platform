import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context);

    if (provider.currentIndex == null) return const SizedBox();

    final song = provider.songs[provider.currentIndex!];
    final isPlaying = provider.audioPlayer.playing;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerScreen()),
      ),
      child: Container(
        width: double.infinity, // ✅ FULL WIDTH
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1F4E5F),
              Color(0xFF0F2C34),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          // ✅ SUBTLE TOP SEPARATOR (NOT FLOATING)
          border: const Border(
            top: BorderSide(color: Colors.white12),
          ),

          // ✅ INNER DEPTH (NOT CARD SHADOW)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 🎵 ICON
            Container(
              height: 42,
              width: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.tealAccent, Colors.teal],
                ),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.black,
              ),
            ),

            const SizedBox(width: 12),

            // 🎶 TITLE + ARTIST
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ⏯ PLAY / PAUSE
            IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 36,
              ),
              color: Colors.white,
              onPressed: () {
                isPlaying ? provider.pause() : provider.resume();
              },
            ),

            // ⏭ NEXT
            IconButton(
              icon: const Icon(Icons.skip_next),
              color: Colors.white70,
              onPressed: provider.playNext,
            ),
          ],
        ),
      ),
    );
  }
}
