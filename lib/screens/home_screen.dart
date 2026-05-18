import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import '../screens/player_screen.dart';
import '../theme/app_theme.dart';
import '../services/queue_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool scanning = false;
  bool showSearch = false;
  String query = '';

  // ── Queue filter state ──
  List<SongQueue> _queues = [];
  String? _selectedQueueId; // null = "All"

  @override
  void initState() {
    super.initState();
    _autoLoadSongs();
    _loadQueues();
  }

  Future<void> _autoLoadSongs() async {
    setState(() => scanning = true);
    final provider = Provider.of<PlayerProvider>(context, listen: false);
    await provider.loadSongs();
    setState(() => scanning = false);
  }

  Future<void> _loadQueues() async {
    final queues = await QueueStorageService.load();
    if (mounted) setState(() => _queues = queues);
  }

  /// Reload queues every time the screen comes back into focus
  /// (so newly created/renamed queues appear instantly)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadQueues();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context);

    // ── 1. Apply queue filter ──
    final queueFilteredSongs = _selectedQueueId == null
        ? provider.songs
        : provider.songs
        .where((s) {
      final q = _queues.firstWhere(
            (q) => q.id == _selectedQueueId,
        orElse: () => SongQueue(id: '', name: ''),
      );
      return q.songUris.contains(s.uri);
    })
        .toList();

    // ── 2. Apply search filter on top ──
    final songs = queueFilteredSongs.where((s) {
      final q = query.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.body),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero App Bar ──
            SliverToBoxAdapter(child: _buildHeader(provider)),

            // ── Search bar ──
            if (showSearch)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: AppDecorations.searchField,
                    child: TextField(
                      autofocus: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Search songs or artists...',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                        icon: Icon(Icons.search,
                            color: AppColors.textMuted, size: 20),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                ),
              ),

            // ── Queue filter chips ──
            if (_queues.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildQueueChips(),
                ),
              ),

            // ── Section label ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                child: Row(
                  children: [
                    Text(
                      query.isEmpty ? 'All Songs' : 'Results',
                      style: AppTextStyles.sectionLabel,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${songs.length}',
                        style: TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Song list ──
            if (scanning)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.red),
                ),
              )
            else if (songs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.music_off_rounded,
                            color: AppColors.textMuted, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text('No songs found',
                          style: AppTextStyles.emptyPrimary),
                      const SizedBox(height: 6),
                      Text(
                        _selectedQueueId != null
                            ? 'This queue has no songs yet'
                            : 'Add music to get started',
                        style: AppTextStyles.emptySecondary,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final song = songs[index];
                      final realIndex = provider.songs.indexOf(song);

                      // ── Double guard:
                      //    1. currentIndex must be non-null (user has played something)
                      //    2. index must actually match
                      final isCurrentlyPlaying =
                          provider.currentIndex != null &&
                              provider.currentIndex == realIndex;

                      return SongTile(
                        songId: song.id,
                        title: song.title,
                        subtitle: song.artist,
                        isFav: provider.favouriteUris.contains(song.uri),
                        isPlaying: isCurrentlyPlaying,
                        // Tapping the already-playing tile → go to PlayerScreen
                        onTapWhenPlaying: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PlayerScreen()),
                        ),
                        onFavTap: () => provider.toggleFavourite(song.uri),
                        onTap: () {
                          if (_selectedQueueId != null) {
                            // A queue chip is active → play only that queue's songs
                            final selectedQueue = _queues.firstWhere(
                                  (q) => q.id == _selectedQueueId,
                              orElse: () => SongQueue(id: '', name: ''),
                            );
                            if (selectedQueue.id.isNotEmpty) {
                              provider.playQueueAtIndex(
                                  selectedQueue.songUris, index);
                              return;
                            }
                          }
                          // No chip selected → play from full list
                          provider.playSongAtIndex(realIndex);
                        },
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Queue filter chips row ──
  Widget _buildQueueChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          _QueueChip(
            label: 'All',
            icon: Icons.music_note_rounded,
            isSelected: _selectedQueueId == null,
            onTap: () => setState(() => _selectedQueueId = null),
          ),
          const SizedBox(width: 8),
          // One chip per queue — pass emoji if set
          ..._queues.asMap().entries.map((entry) {
            final q = entry.value;
            final accent = _queueAccent(q.name);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _QueueChip(
                label: q.name,
                icon: Icons.queue_music_rounded,
                emoji: q.icon.isNotEmpty ? q.icon : null,
                isSelected: _selectedQueueId == q.id,
                accentColor: accent,
                onTap: () => setState(() => _selectedQueueId == q.id
                    ? _selectedQueueId = null
                    : _selectedQueueId = q.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Same accent logic as _QueueCard so colours match
  Color _queueAccent(String name) {
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) * 37) % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.65, 0.55).toColor();
  }

  Widget _buildHeader(PlayerProvider provider) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.graphic_eq,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text('Beatly', style: AppTextStyles.appName),
                  const Spacer(),
                  // Search button
                  _NavIconBtn(
                    icon: showSearch ? Icons.close : Icons.search,
                    isActive: showSearch,
                    onTap: () => setState(() {
                      showSearch = !showSearch;
                      query = '';
                    }),
                  ),
                  // Shuffle button
                  _NavIconBtn(
                    icon: Icons.shuffle_rounded,
                    isActive: provider.isShuffling,
                    onTap: provider.toggleShuffleAll,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Text('Feel the Beat', style: AppTextStyles.tagline),
            ),
            const SizedBox(height: 14),
            Container(height: 0.5, color: AppColors.red.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QUEUE CHIP
// ─────────────────────────────────────────────

class _QueueChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? emoji; // shown instead of icon when set
  final bool isSelected;
  final Color? accentColor;
  final VoidCallback onTap;

  const _QueueChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.emoji,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.red : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.red : AppColors.red.withOpacity(0.3),
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.red.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null && emoji!.isNotEmpty)
              Text(emoji!, style: const TextStyle(fontSize: 13))
            else
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.red),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NAV ICON BUTTON
// ─────────────────────────────────────────────

class _NavIconBtn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIconBtn({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.red.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(
              color: AppColors.red.withOpacity(0.4), width: 0.8)
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.red : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}