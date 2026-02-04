import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';

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
          children: const [
            Text(
              'Favourites',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your loved tracks ❤️',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white60,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
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
        child: favSongs.isEmpty
            ? const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                color: Colors.white38,
                size: 64,
              ),
              SizedBox(height: 14),
              Text(
                'No favourite songs yet',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tap ❤️ to save your vibe',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          itemCount: favSongs.length,
          itemBuilder: (context, index) {
            final song = favSongs[index];
            final realIndex = provider.songs
                .indexWhere((s) => s.uri == song.uri);

            return SongTile(
              title: song.title,
              subtitle: song.artist,
              isFav: true,
              isPlaying: provider.currentIndex == realIndex,
              onFavTap: () =>
                  provider.toggleFavourite(song.uri),
              onTap: () =>
                  provider.playSongAtIndex(realIndex),
            );
          },
        ),
      ),
    );
  }
}
