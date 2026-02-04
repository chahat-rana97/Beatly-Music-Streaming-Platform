import 'package:flutter/material.dart';

class SongTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onFavTap;
  final bool isFav;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onFavTap,
    this.isFav = false,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isPlaying
              ? const LinearGradient(
            colors: [
              Color(0xFF1F4E5F),
              Color(0xFF0F2C34),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: isPlaying
                  ? Colors.tealAccent.withOpacity(0.35)
                  : Colors.black.withOpacity(0.4),
              blurRadius: isPlaying ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isPlaying
                ? Colors.tealAccent.withOpacity(0.6)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            // 🎵 ICON / PLAYING INDICATOR
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isPlaying
                    ? const LinearGradient(
                  colors: [Colors.tealAccent, Colors.teal],
                )
                    : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: Icon(
                isPlaying ? Icons.equalizer : Icons.music_note,
                color: isPlaying ? Colors.black : Colors.white70,
              ),
            ),

            const SizedBox(width: 14),

            // 🎶 TITLE + ARTIST
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight:
                      isPlaying ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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

            // ❤️ FAV
            IconButton(
              onPressed: onFavTap,
              icon: isFav
                  ? ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [Colors.tealAccent, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white, // required for ShaderMask
                ),
              )
                  : const Icon(
                Icons.favorite_border,
                color: Colors.white54,
              ),
            ),

          ],
        ),
      ),
    );
  }
}
