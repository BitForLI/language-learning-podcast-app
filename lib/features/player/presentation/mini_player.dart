import 'package:flutter/material.dart';

import '../application/playback_controller.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.controller});

  final PlaybackController controller;

  @override
  Widget build(BuildContext context) {
    const foreground = Color(0xFF202124);
    const secondary = Color(0xFF55575C);
    return Material(
      key: const ValueKey('mini_player'),
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            minHeight: 2,
            color: foreground,
            value: controller.duration == Duration.zero
                ? 0
                : (controller.position.inMilliseconds /
                          controller.duration.inMilliseconds)
                      .clamp(0, 1),
            backgroundColor: Colors.transparent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                _MiniArtwork(url: controller.artworkUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.episode!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                      if (controller.podcastTitle != null)
                        Text(
                          controller.podcastTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: secondary),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  color: foreground,
                  tooltip: controller.playing ? '暂停' : '播放',
                  onPressed: controller.togglePlayPause,
                  icon: Icon(
                    controller.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                IconButton(
                  color: foreground,
                  tooltip: '前进 30 秒',
                  onPressed: () => controller.skip(const Duration(seconds: 30)),
                  icon: const Icon(Icons.forward_30_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: const SizedBox.square(
        dimension: 46,
        child: Icon(Icons.podcasts_rounded),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null || url!.isEmpty
          ? fallback
          : Image.network(
              url!,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
    );
  }
}
