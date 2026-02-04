import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool scanning = false;
  bool showSearch = false;
  String query = '';

  @override
  void initState() {
    super.initState();
    _autoLoadSongs();
  }

  Future<void> _autoLoadSongs() async {
    setState(() => scanning = true);
    final provider = Provider.of<PlayerProvider>(context, listen: false);
    await provider.loadSongs();
    setState(() => scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context);

    final songs = provider.songs.where((s) {
      final q = query.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2C34),
                  Color(0xFF1F4E5F),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 TOP ROW
                    Row(
                      children: [
                        const Icon(
                          Icons.graphic_eq,
                          color: Colors.tealAccent,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Beatly',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),

                        // 🔍 SEARCH ICON (icon only, no box)
                        IconButton(
                          icon: Icon(
                            showSearch ? Icons.close : Icons.search,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              showSearch = !showSearch;
                              query = '';
                            });
                          },
                        ),


                        // 🔀 SHUFFLE ALL
                        IconButton(
                          icon: Icon(
                            Icons.shuffle,
                            shadows: provider.isShuffling
                                ? [
                              Shadow(
                                color: Colors.tealAccent.withOpacity(0.6),
                                blurRadius: 10,
                              )
                            ]
                                : [],
                          ),
                          color: provider.isShuffling
                              ? Colors.tealAccent
                              : Colors.white70,
                          onPressed: provider.toggleShuffleAll,
                        ),


                      ],
                    ),

                    const SizedBox(height: 5),

                    // 🎵 TAGLINE (ALWAYS VISIBLE)
                    const Text(
                      'Feel the Beat • All Songs',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                        letterSpacing: 0.8,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ✨ DIVIDER
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.tealAccent.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        child: Column(
          children: [

            // 🔍 SEARCH BAR (NO OVERFLOW)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: showSearch
                  ? Padding(
                key: const ValueKey(1),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.tealAccent.withOpacity(0.4),
                    ),
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search songs or artists...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      icon: Icon(Icons.search,
                          color: Colors.white54, size: 20),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
              )
                  : const Padding(
                key: ValueKey(2),
                padding: EdgeInsets.only(top: 2, bottom: 1),
                child: Text(
                  'Feel the Beat • All Songs',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

            // 🎵 SONG LIST
            Expanded(
              child: scanning
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.tealAccent,
                ),
              )
                  : songs.isEmpty
                  ? const Center(
                child: Text(
                  'No songs found 🎵',
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final realIndex =
                  provider.songs.indexOf(song);

                  return SongTile(
                    title: song.title,
                    subtitle: song.artist,
                    isFav: provider.favouriteUris
                        .contains(song.uri),
                    isPlaying:
                    provider.currentIndex == realIndex,
                    onFavTap: () =>
                        provider.toggleFavourite(song.uri),
                    onTap: () =>
                        provider.playSongAtIndex(realIndex),
                  );
                },
              ),
            ),
          ],
        ),
      ),


    );
  }
}
