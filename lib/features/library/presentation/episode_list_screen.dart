import 'package:flutter/material.dart';

import '../application/library_controller.dart';
import '../domain/podcast.dart';
import 'podcast_artwork.dart';

class EpisodeListScreen extends StatefulWidget {
  const EpisodeListScreen({
    super.key,
    required this.podcast,
    required this.controller,
    this.onPlayEpisode,
  });

  final Podcast podcast;
  final LibraryController controller;
  final void Function(Podcast podcast, Episode episode)? onPlayEpisode;

  @override
  State<EpisodeListScreen> createState() => _EpisodeListScreenState();
}

class _EpisodeListScreenState extends State<EpisodeListScreen> {
  late final Future<List<Episode>> _episodes = widget.controller.episodes(
    widget.podcast.id,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.podcast.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<List<Episode>>(
        future: _episodes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final episodes = snapshot.data ?? const [];
          if (episodes.isEmpty) {
            return const Center(child: Text('这个播客暂时没有可播放的单集'));
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _ShowHeader(podcast: widget.podcast)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '最新单集',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                sliver: SliverList.separated(
                  itemCount: episodes.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final episode = episodes[index];
                    return _EpisodeRow(
                      episode: episode,
                      metadata: _episodeMetadata(episode),
                      artworkUrl: widget.podcast.artworkUrl,
                      onPlay: () =>
                          widget.onPlayEpisode?.call(widget.podcast, episode),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _episodeMetadata(Episode episode) {
    final values = <String>[];
    final date = episode.publishedAt?.toLocal();
    if (date != null) values.add('${date.year}-${date.month}-${date.day}');
    final seconds = episode.durationSeconds;
    if (seconds != null) {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      values.add(hours > 0 ? '$hours 小时 $minutes 分' : '$minutes 分钟');
    }
    return values.isEmpty ? '已同步' : values.join(' · ');
  }
}

class _ShowHeader extends StatelessWidget {
  const _ShowHeader({required this.podcast});

  final Podcast podcast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PodcastArtwork(url: podcast.artworkUrl, size: 104),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    if (podcast.author?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        podcast.author!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${podcast.episodeCount} 集',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (podcast.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              podcast.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({
    required this.episode,
    required this.metadata,
    required this.artworkUrl,
    required this.onPlay,
  });

  final Episode episode;
  final String metadata;
  final String? artworkUrl;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PodcastArtwork(url: artworkUrl, size: 62),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    metadata,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  if (episode.transcriptReady ||
                      episode.hasTranscriptSource) ...[
                    const SizedBox(height: 5),
                    Text(
                      episode.transcriptReady ? '文本已就绪' : '提供时间轴文本',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.more_horiz_rounded, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
