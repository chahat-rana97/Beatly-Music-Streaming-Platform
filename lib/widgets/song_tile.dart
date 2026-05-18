import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../theme/app_theme.dart';

class SongTile extends StatelessWidget {
  final int songId;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onFavTap;
  final bool isFav;
  final bool isPlaying;
  // When non-null, tapping a currently-playing tile calls this
  // instead of onTap (e.g. navigate to PlayerScreen).
  final VoidCallback? onTapWhenPlaying;

  const SongTile({
    super.key,
    required this.songId,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onFavTap,
    this.isFav = false,
    this.isPlaying = false,
    this.onTapWhenPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // If currently playing and a special handler is provided, use it;
      // otherwise fall through to the normal onTap.
      onTap: isPlaying ? (onTapWhenPlaying ?? onTap) : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.red.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaying
                ? AppColors.red.withOpacity(0.35)
                : AppColors.surfaceBorder,
            width: isPlaying ? 1.0 : 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // ── Album art with playing overlay ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: QueryArtworkWidget(
                      id: songId,
                      type: ArtworkType.AUDIO,
                      artworkWidth: 52,
                      artworkHeight: 52,
                      artworkFit: BoxFit.cover,
                      artworkBorder: BorderRadius.zero,
                      keepOldArtwork: true,
                      nullArtworkWidget: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? AppColors.red.withOpacity(0.2)
                              : AppColors.iconCircle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          color: isPlaying
                              ? AppColors.red
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  // Playing pulse overlay
                  if (isPlaying)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: AppColors.red.withOpacity(0.18),
                          child: const Center(
                            child: Icon(
                              Icons.equalizer_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // ── Title + artist ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPlaying
                            ? AppColors.red
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight:
                        isPlaying ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: isPlaying ? 0.1 : 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              ),

              // ── Now playing badge ──
              if (isPlaying) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.red.withOpacity(0.3), width: 0.5),
                  ),
                  child: Text(
                    'NOW',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // ── Favourite button ──
              GestureDetector(
                onTap: onFavTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isFav
                        ? AppColors.red.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFav ? AppColors.red : AppColors.textMuted,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}