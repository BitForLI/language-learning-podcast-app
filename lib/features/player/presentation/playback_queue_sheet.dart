part of 'player_screen.dart';

class _PlaybackQueueSheet extends StatefulWidget {
  const _PlaybackQueueSheet({
    required this.repository,
    required this.currentEpisode,
    required this.onPlay,
    this.podcastTitle,
    this.artworkUrl,
  });

  final PodcastRepository repository;
  final Episode currentEpisode;
  final ValueChanged<Episode> onPlay;
  final String? podcastTitle;
  final String? artworkUrl;

  @override
  State<_PlaybackQueueSheet> createState() => _PlaybackQueueSheetState();
}

class _PlaybackQueueSheetState extends State<_PlaybackQueueSheet> {
  late final Future<List<Episode>> _episodes = widget.repository.listEpisodes(
    widget.currentEpisode.podcastId,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        hazeScreenInset,
        0,
        hazeScreenInset,
        hazeScreenInset,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.76,
        child: GlassSurface(
          blur: hazeControlGlassBlur,
          tint: hazeControlGlassTint,
          borderRadius: BorderRadius.circular(28),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10, bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF77797E),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.queue_music_rounded,
                        color: Color(0xFF202124),
                        size: 27,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '播放队列',
                              style: TextStyle(
                                color: Color(0xFF202124),
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (widget.podcastTitle?.isNotEmpty == true)
                              Text(
                                widget.podcastTitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF5F6368),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭播放队列',
                        color: const Color(0xFF202124),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.black12),
                Expanded(
                  child: FutureBuilder<List<Episode>>(
                    future: _episodes,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF303134),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return _QueueMessage(
                          icon: Icons.cloud_off_rounded,
                          message: snapshot.error.toString(),
                        );
                      }
                      final episodes = (snapshot.data ?? const <Episode>[])
                          .where(
                            (episode) => episode.id != widget.currentEpisode.id,
                          )
                          .toList();
                      if (episodes.isEmpty) {
                        return const _QueueMessage(
                          icon: Icons.queue_music_rounded,
                          message: '这个播客暂时没有其他单集',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                        itemCount: episodes.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: Colors.black12, indent: 76),
                        itemBuilder: (context, index) {
                          final episode = episodes[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            leading: _QueueArtwork(url: widget.artworkUrl),
                            title: Text(
                              episode.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF202124),
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            subtitle: Text(
                              _episodeMetadata(episode),
                              style: const TextStyle(color: Color(0xFF5F6368)),
                            ),
                            trailing: const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF303134),
                            ),
                            onTap: () => widget.onPlay(episode),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QueueArtwork extends StatelessWidget {
  const _QueueArtwork({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: Color(0xFFD6D7DA),
      child: SizedBox.square(
        dimension: 52,
        child: Icon(Icons.podcasts_rounded, color: Color(0xFF4A4C50)),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: url == null || url!.isEmpty
          ? fallback
          : Image.network(
              url!,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
    );
  }
}

class _QueueMessage extends StatelessWidget {
  const _QueueMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Color(0xFF4A4C50)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4A4C50)),
            ),
          ],
        ),
      ),
    );
  }
}
