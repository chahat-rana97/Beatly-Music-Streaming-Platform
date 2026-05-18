import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import '../theme/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context);

    if (provider.currentIndex == null) return const SizedBox();

    final song = provider.songs[provider.currentIndex!];
    final isPlaying = provider.audioPlayer.playing;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: AppDecorations.miniPlayerBar,
      child: Row(
        children: [
          // ── Tappable area (art + title) → opens PlayerScreen ──
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              ),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  // ── Album art ──
                  ClipRRect(
                    borderRadius: AppRadius.xsBorderRadius,
                    child: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkWidth: 44,
                      artworkHeight: 44,
                      artworkFit: BoxFit.cover,
                      artworkBorder: BorderRadius.zero,
                      keepOldArtwork: true,
                      nullArtworkWidget: Container(
                        width: 44,
                        height: 44,
                        decoration: AppDecorations.playButton,
                        child: const Icon(Icons.music_note,
                            color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ── Title + artist ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.miniTitle),
                        const SizedBox(height: 2),
                        Text(song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.miniArtist),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Play / Pause (independent tap) ──
          IconButton(
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              size: 36,
              color: AppColors.textPrimary,
            ),
            onPressed: () =>
            isPlaying ? provider.pause() : provider.resume(),
          ),

          // ── Next (independent tap) ──
          IconButton(
            icon: const Icon(Icons.skip_next,
                color: AppColors.textSecondary),
            onPressed: provider.playNext,
          ),
        ],
      ),
    );
  }
}