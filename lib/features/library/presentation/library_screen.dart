import 'dart:async';

import 'package:flutter/material.dart';

import '../application/library_controller.dart';
import '../data/local_podcast_repository.dart';
import '../data/podcast_repository.dart';
import '../domain/podcast.dart';
import 'add_subscription_sheet.dart';
import 'episode_list_screen.dart';
import 'podcast_artwork.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    this.repository,
    this.onPlayEpisode,
    this.onPodcastsChanged,
  });

  final PodcastRepository? repository;
  final void Function(Podcast podcast, Episode episode)? onPlayEpisode;
  final ValueChanged<List<Podcast>>? onPodcastsChanged;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final LibraryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LibraryController(
      widget.repository ?? LocalPodcastRepository(),
    )..addListener(_onChanged);
    unawaited(_load());
  }

  Future<void> _load() async {
    await _controller.load();
    _notifyPodcastsChanged();
  }

  void _notifyPodcastsChanged() {
    if (_controller.errorMessage == null) {
      widget.onPodcastsChanged?.call(List.unmodifiable(_controller.podcasts));
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _showAddSheet() async {
    if (!_controller.canAdd) {
      _showMessage('最多只能收藏 10 个播客');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddSubscriptionSheet(controller: _controller),
    );
    _notifyPodcastsChanged();
  }

  Future<void> _refresh() async {
    try {
      final result = await _controller.refresh();
      _notifyPodcastsChanged();
      if (!mounted) return;
      final message = result.failures.isEmpty
          ? '更新完成，新增 ${result.newEpisodes} 集'
          : '更新完成；${result.failures.length} 个播客失败';
      _showMessage(message);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDelete(Podcast podcast) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消收藏？'),
        content: Text('“${podcast.title}”及已同步的单集会从本机移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('保留'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _controller.delete(podcast.id);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 68,
          title: Text(
            'BANK',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: '刷新订阅',
              onPressed: _controller.isRefreshing ? null : _refresh,
              icon: _controller.isRefreshing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: '添加播客',
              onPressed: _controller.canAdd ? _showAddSheet : null,
              icon: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
          sliver: SliverList.list(
            children: [
              if (_controller.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_controller.errorMessage != null)
                _LoadError(
                  message: _controller.errorMessage!,
                  onRetry: _controller.load,
                )
              else if (_controller.podcasts.isEmpty)
                _LibraryEmptyState(onAdd: _showAddSheet)
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _controller.podcasts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    final podcast = _controller.podcasts[index];
                    return _PodcastCard(
                      podcast: podcast,
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => EpisodeListScreen(
                            podcast: podcast,
                            controller: _controller,
                            onPlayEpisode: widget.onPlayEpisode,
                          ),
                        ),
                      ),
                      onDelete: () => _confirmDelete(podcast),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 44),
        child: Column(
          children: [
            Icon(Icons.podcasts_rounded, size: 56, color: colors.primary),
            const SizedBox(height: 20),
            Text('还没有收藏播客', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '可以搜索 Apple Podcasts，或直接粘贴 RSS 地址。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加播客'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodcastCard extends StatelessWidget {
  const _PodcastCard({
    required this.podcast,
    required this.onOpen,
    required this.onDelete,
  });

  final Podcast podcast;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  PodcastArtwork(
                    url: podcast.artworkUrl,
                    size: constraints.maxWidth,
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onDelete,
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                podcast.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                podcast.author?.isNotEmpty == true
                    ? podcast.author!
                    : '${podcast.episodeCount} 集',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
