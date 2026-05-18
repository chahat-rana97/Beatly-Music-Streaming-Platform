import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import '../theme/app_theme.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context);

    final favSongs = provider.songs
        .where((s) => provider.favouriteUris.contains(s.uri))
        .toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Favourites', style: AppTextStyles.h1),
            const SizedBox(height: 4),
            Text('Your loved tracks', style: AppTextStyles.tagline),
          ],
        ),
        flexibleSpace: Container(color: AppColors.surface),
      ),

      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.body),
        child: favSongs.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_border,
                  color: AppColors.textMuted, size: 64),
              const SizedBox(height: 14),
              Text('No favourite songs yet',
                  style: AppTextStyles.emptyPrimary),
              const SizedBox(height: 6),
              Text('Tap the heart to save your vibe',
                  style: AppTextStyles.emptySecondary),
            ],
          ),
        )
            : ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          itemCount: favSongs.length,
          itemBuilder: (context, index) {
            final song = favSongs[index];
            final realIndex =
            provider.songs.indexWhere((s) => s.uri == song.uri);

            return SongTile(
              songId: song.id,
              title: song.title,
              subtitle: song.artist,
              isFav: true,
              isPlaying: provider.currentIndex == realIndex,
              onFavTap: () => provider.toggleFavourite(song.uri),
              onTap: () => provider.playSongAtIndex(realIndex),
            );
          },
        ),
      ),
    );
  }
}