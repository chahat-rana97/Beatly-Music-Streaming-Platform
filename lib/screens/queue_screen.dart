import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../services/queue_storage_service.dart';
import '../screens/player_screen.dart';

export '../services/queue_storage_service.dart' show SongQueue;

// ─────────────────────────────────────────────
//  QUEUE SCREEN  (shown inside MainScreen tab)
// ─────────────────────────────────────────────

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen>
    with SingleTickerProviderStateMixin {
  List<SongQueue> _queues = [];
  bool _loading = true;
  late AnimationController _fabAnim;

  // ── When non-null, we show QueueDetailScreen inline ──
  SongQueue? _openedQueue;
  int? _openedIndex;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _loadQueues();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  Future<void> _loadQueues() async {
    final saved = await QueueStorageService.load();
    if (mounted) setState(() { _queues = saved; _loading = false; });
  }

  Future<void> _persist() => QueueStorageService.save(_queues);

  Future<void> _showCreateQueueDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<_QueueDialogResult>(
      context: context,
      builder: (ctx) => _QueueNameDialog(controller: controller),
    );
    if (result != null && result.name.trim().isNotEmpty) {
      setState(() {
        _queues.add(SongQueue(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result.name.trim(),
          icon: result.icon,
        ));
      });
      await _persist();
    }
  }

  Future<void> _renameQueue(int index) async {
    final controller = TextEditingController(text: _queues[index].name);
    final result = await showDialog<_QueueDialogResult>(
      context: context,
      builder: (ctx) => _QueueNameDialog(
        controller: controller,
        isRename: true,
        initialIcon: _queues[index].icon,
      ),
    );
    if (result != null && result.name.trim().isNotEmpty) {
      setState(() {
        _queues[index].name = result.name.trim();
        _queues[index].icon = result.icon;
      });
      await _persist();
    }
  }

  Future<void> _deleteQueue(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Queue', style: AppTextStyles.h3),
        content: Text(
          'Delete "${_queues[index].name}"? This cannot be undone.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
            Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // If the deleted queue is currently open, close it
      if (_openedIndex == index) {
        setState(() { _openedQueue = null; _openedIndex = null; });
      }
      setState(() => _queues.removeAt(index));
      await _persist();
    }
  }

  void _openQueue(int index) {
    setState(() {
      _openedQueue = _queues[index];
      _openedIndex = index;
    });
  }

  /// Called by QueueDetailScreen to pop back to the list
  void _closeDetail() {
    setState(() { _openedQueue = null; _openedIndex = null; });
  }

  @override
  Widget build(BuildContext context) {
    // ── Show detail inline (no Navigator.push → bottom nav stays visible) ──
    if (_openedQueue != null) {
      return QueueDetailScreen(
        queue: _openedQueue!,
        onUpdate: () async {
          setState(() {}); // refresh card song count
          await _persist();
        },
        onBack: _closeDetail,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.body),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(color: AppColors.red))
                  : _queues.isEmpty
                  ? _buildEmptyState()
                  : _buildQueueList(),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: _showCreateQueueDialog,
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'New Queue',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.queue_music_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text('My Queues', style: AppTextStyles.appName),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_queues.length}',
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: Text('Your personal playlists',
                  style: AppTextStyles.tagline),
            ),
            Container(height: 0.5, color: AppColors.red.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: AppColors.red.withOpacity(0.25), width: 1.5),
            ),
            child: const Icon(Icons.queue_music_rounded,
                color: AppColors.textMuted, size: 40),
          ),
          const SizedBox(height: 20),
          Text('No queues yet', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('Tap + to create your first queue',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildQueueList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: _queues.length,
      itemBuilder: (context, index) {
        final q = _queues[index];
        return _QueueCard(
          queue: q,
          onTap: () => _openQueue(index),
          onRename: () => _renameQueue(index),
          onDelete: () => _deleteQueue(index),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  QUEUE CARD
// ─────────────────────────────────────────────

class _QueueCard extends StatelessWidget {
  final SongQueue queue;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _QueueCard({
    required this.queue,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  Color _accentColor() {
    final hue = (queue.name.codeUnits.fold(0, (a, b) => a + b) * 37) % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.65, 0.55).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final count = queue.songUris.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border:
                  Border.all(color: accent.withOpacity(0.3), width: 1),
                ),
                child: queue.icon.isNotEmpty
                    ? Center(
                  child: Text(
                    queue.icon,
                    style: const TextStyle(fontSize: 26),
                  ),
                )
                    : Icon(Icons.queue_music_rounded, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      queue.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count == 0
                          ? 'Empty queue'
                          : '$count song${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted, size: 20),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (val) {
                  if (val == 'rename') onRename();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded,
                            color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 10),
                        Text('Rename',
                            style:
                            TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: AppColors.red, size: 18),
                        const SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(color: AppColors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QUEUE DETAIL SCREEN
//  • No longer uses Navigator.push → bottom nav stays visible
//  • FAB automatically rises above MiniPlayer when song is playing
// ─────────────────────────────────────────────

// Mini player height: 44px art + 20px vertical padding = 64px total
const double _miniPlayerHeight = 64.0;

class QueueDetailScreen extends StatefulWidget {
  final SongQueue queue;
  final VoidCallback onUpdate;
  /// Called to pop back to the queue list (replaces Navigator.pop)
  final VoidCallback onBack;

  const QueueDetailScreen({
    super.key,
    required this.queue,
    required this.onUpdate,
    required this.onBack,
  });

  @override
  State<QueueDetailScreen> createState() => _QueueDetailScreenState();
}

class _QueueDetailScreenState extends State<QueueDetailScreen> {
  String _searchQuery = '';
  bool _showAddPanel = false;

  List<dynamic> _getQueueSongs(PlayerProvider provider) => provider.songs
      .where((s) => widget.queue.songUris.contains(s.uri))
      .toList();

  List<dynamic> _getAvailableSongs(PlayerProvider provider) {
    final q = _searchQuery.toLowerCase();
    return provider.songs
        .where((s) =>
    !widget.queue.songUris.contains(s.uri) &&
        (q.isEmpty ||
            s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q)))
        .toList();
  }

  void _addSong(String uri) {
    setState(() => widget.queue.songUris.add(uri));
    widget.onUpdate();
  }

  void _removeSong(String uri) {
    setState(() => widget.queue.songUris.remove(uri));
    widget.onUpdate();
  }

  void _playSong(PlayerProvider provider, String uri, bool isPlaying) {
    if (isPlaying) {
      // Already playing → go to PlayerScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerScreen()),
      );
      return;
    }
    final indexInQueue = widget.queue.songUris.indexOf(uri);
    if (indexInQueue != -1) {
      provider.playQueueAtIndex(widget.queue.songUris, indexInQueue);
    }
  }
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context);
    final queueSongs = _getQueueSongs(provider);
    final available = _getAvailableSongs(provider);

    // No Scaffold here — QueueDetailScreen renders inside MainScreen's Scaffold.
    // Using a plain Stack so the FAB can be precisely positioned above MiniPlayer.
    return Stack(
      children: [
        // ── Background gradient ──
        Container(decoration: const BoxDecoration(gradient: AppGradients.body)),
        // ── Main content ──
        Column(
          children: [
            _buildHeader(queueSongs.length),
            Expanded(
              child: _showAddPanel
                  ? _buildAddPanel(available, provider)
                  : _buildQueueContent(queueSongs, provider),
            ),
          ],
        ),
        // ── FAB: 16px from the bottom of the content area (Stack ends above MiniPlayer) ──
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'queue_detail_fab',
            onPressed: () => setState(() => _showAddPanel = !_showAddPanel),
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            elevation: 6,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showAddPanel ? Icons.check_rounded : Icons.add_rounded,
                key: ValueKey(_showAddPanel),
              ),
            ),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _showAddPanel ? 'Done' : 'Add Songs',
                key: ValueKey(_showAddPanel),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int songCount) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
              child: Row(
                children: [
                  // ── Uses onBack instead of Navigator.pop ──
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.queue.name,
                          style: AppTextStyles.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$songCount song${songCount == 1 ? '' : 's'}',
                          style: AppTextStyles.tagline,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(height: 0.5, color: AppColors.red.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueContent(List<dynamic> songs, PlayerProvider provider) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: AppColors.red.withOpacity(0.2), width: 1.5),
              ),
              child: const Icon(Icons.library_music_outlined,
                  color: AppColors.textMuted, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Queue is empty', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text('Tap "Add Songs" to fill it up',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: songs.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final uri = widget.queue.songUris.removeAt(oldIndex);
          widget.queue.songUris.insert(newIndex, uri);
        });
        widget.onUpdate();
      },
      itemBuilder: (context, index) {
        final song = songs[index];
        final isPlaying =
            provider.songs.indexOf(song) == provider.currentIndex;
        return _QueueSongTile(
          key: ValueKey(song.uri),
          songId: song.id,
          title: song.title,
          artist: song.artist,
          isPlaying: isPlaying,
          onTap: () => _playSong(provider, song.uri, isPlaying), // pass isPlaying
          onRemove: () => _removeSong(song.uri),
        );
      },
    );
  }

  Widget _buildAddPanel(List<dynamic> available, PlayerProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: AppDecorations.searchField,
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search songs...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                icon: Icon(Icons.search,
                    color: AppColors.textMuted, size: 20),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Row(
            children: [
              Text('All Songs', style: AppTextStyles.sectionLabel),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${available.length}',
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
        Expanded(
          child: available.isEmpty
              ? Center(
              child: Text('No songs to add',
                  style: AppTextStyles.bodySmall))
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: available.length,
            itemBuilder: (context, index) {
              final song = available[index];
              return _AddSongTile(
                key: ValueKey(song.uri),
                songId: song.id,
                title: song.title,
                artist: song.artist,
                onAdd: () => _addSong(song.uri),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  QUEUE SONG TILE
// ─────────────────────────────────────────────

class _QueueSongTile extends StatelessWidget {
  final int songId;
  final String title;
  final String artist;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueSongTile({
    super.key,
    required this.songId,
    required this.title,
    required this.artist,
    required this.isPlaying,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.drag_indicator_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
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
                        child: Icon(Icons.music_note_rounded,
                            color: isPlaying
                                ? AppColors.red
                                : AppColors.textSecondary,
                            size: 22),
                      ),
                    ),
                  ),
                  if (isPlaying)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: AppColors.red.withOpacity(0.18),
                          child: const Center(
                            child: Icon(Icons.equalizer_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
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
                    Text(artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label),
                  ],
                ),
              ),
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
                  child: Text('NOW',
                      style: TextStyle(
                          color: AppColors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ),
                const SizedBox(width: 4),
              ],
              GestureDetector(
                onTap: onRemove,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.remove_rounded,
                      color: AppColors.red, size: 19),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ADD SONG TILE
// ─────────────────────────────────────────────

class _AddSongTile extends StatelessWidget {
  final int songId;
  final String title;
  final String artist;
  final VoidCallback onAdd;

  const _AddSongTile({
    super.key,
    required this.songId,
    required this.title,
    required this.artist,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
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
                    color: AppColors.iconCircle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.music_note_rounded,
                      color: AppColors.textSecondary, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label),
                ],
              ),
            ),
            GestureDetector(
              onTap: onAdd,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.red.withOpacity(0.3), width: 0.8),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.red, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DIALOG RESULT
// ─────────────────────────────────────────────

class _QueueDialogResult {
  final String name;
  final String icon; // emoji or '' for default
  const _QueueDialogResult({required this.name, required this.icon});
}

// ─────────────────────────────────────────────
//  QUEUE NAME + ICON DIALOG
// ─────────────────────────────────────────────

/// Emoji options shown in the picker grid
const List<String> _kQueueEmojis = [
  '🎵', '🎶', '🎸', '🎹', '🎺', '🎻', '🥁', '🎤',
  '🎧', '🎼', '🔥', '💥', '⚡', '🌊', '🌙', '☀️',
  '🏋️', '🏃', '🧘', '💃', '🎉', '❤️', '💜', '🖤',
  '🌟', '✨', '🎯', '🚀', '🌈', '🍀', '👑', '💎',
];

class _QueueNameDialog extends StatefulWidget {
  final TextEditingController controller;
  final bool isRename;
  final String initialIcon;

  const _QueueNameDialog({
    required this.controller,
    this.isRename = false,
    this.initialIcon = '',
  });

  @override
  State<_QueueNameDialog> createState() => _QueueNameDialogState();
}

class _QueueNameDialogState extends State<_QueueNameDialog> {
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───────────────── TITLE ─────────────────
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _selectedIcon.isNotEmpty
                          ? Text(
                        _selectedIcon,
                        style: const TextStyle(fontSize: 20),
                      )
                          : const Icon(
                        Icons.queue_music_rounded,
                        color: AppColors.red,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      widget.isRename
                          ? 'Rename Queue'
                          : 'New Queue',
                      style: AppTextStyles.h3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ───────────────── TEXTFIELD ─────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.red.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Queue name...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),

              const SizedBox(height: 10),

              // ───────────────── LABEL ─────────────────
              Row(
                children: [
                  Text(
                    'Choose Icon',
                    style: AppTextStyles.sectionLabel,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    'optional',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),

                  const Spacer(),

                  if (_selectedIcon.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = '';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              // ───────────────── EMOJI GRID ─────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.red.withOpacity(0.12),
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _kQueueEmojis.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final emoji = _kQueueEmojis[index];
                    final isSelected = _selectedIcon == emoji;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon =
                          isSelected ? '' : emoji;
                        });
                      },
                      child: AnimatedContainer(
                        duration:
                        const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.red.withOpacity(0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: isSelected
                              ? Border.all(
                            color: AppColors.red
                                .withOpacity(0.4),
                            width: 1.2,
                          )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ───────────────── BUTTONS ─────────────────
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context, null),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: GestureDetector(
                      onTap: _submit,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            widget.isRename
                                ? 'Save'
                                : 'Create',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    Navigator.pop(
      context,
      _QueueDialogResult(
        name: widget.controller.text,
        icon: _selectedIcon,
      ),
    );
  }
}

