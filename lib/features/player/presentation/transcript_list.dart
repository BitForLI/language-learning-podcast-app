part of 'player_screen.dart';

class _TranscriptList extends StatefulWidget {
  const _TranscriptList({required this.controller});

  final TranscriptController controller;

  @override
  State<_TranscriptList> createState() => _TranscriptListState();
}

class _TranscriptListState extends State<_TranscriptList> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _segmentKeys = {};
  Timer? _resumeFollowingTimer;
  int? _lastActiveSegmentIndex;
  int? _lastEpisodeId;
  bool _lastCanFollow = false;
  bool _followingPaused = false;

  TranscriptController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _lastActiveSegmentIndex = controller.activeSegment?.index;
    _lastEpisodeId = controller.document?.episodeId;
    _lastCanFollow = controller.canFollowPlayback;
    _scheduleActiveSegmentScroll();
  }

  @override
  void didUpdateWidget(covariant _TranscriptList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeIndex = controller.activeSegment?.index;
    final episodeId = controller.document?.episodeId;
    final canFollow = controller.canFollowPlayback;
    if (activeIndex == _lastActiveSegmentIndex &&
        episodeId == _lastEpisodeId &&
        canFollow == _lastCanFollow) {
      return;
    }
    if (episodeId != _lastEpisodeId) _segmentKeys.clear();
    _lastActiveSegmentIndex = activeIndex;
    _lastEpisodeId = episodeId;
    _lastCanFollow = canFollow;
    if (!canFollow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !controller.canFollowPlayback &&
            _scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.offset);
        }
      });
    } else if (!_followingPaused) {
      _scheduleActiveSegmentScroll();
    }
  }

  @override
  void dispose() {
    _resumeFollowingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleActiveSegmentScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_followingPaused) unawaited(_scrollToActiveSegment());
    });
  }

  Future<void> _scrollToActiveSegment() async {
    if (!controller.canFollowPlayback) return;
    final episodeId = controller.document?.episodeId;
    final active = controller.activeSegment;
    if (active == null || !_scrollController.hasClients) return;
    final activeContext = _segmentKeys[active.index]?.currentContext;
    if (activeContext != null) {
      await Scrollable.ensureVisible(
        activeContext,
        alignment: 0.42,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final segments = controller.document?.segments ?? const [];
    final position = segments.indexWhere((item) => item.index == active.index);
    if (position < 0 || segments.length < 2) return;
    final estimatedOffset =
        _scrollController.position.maxScrollExtent *
        position /
        (segments.length - 1);
    await _scrollController.animateTo(
      estimatedOffset.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
    if (!mounted ||
        _followingPaused ||
        !controller.canFollowPlayback ||
        controller.activeSegment?.index != active.index ||
        controller.document?.episodeId != episodeId) {
      return;
    }
    final correctedContext = _segmentKeys[active.index]?.currentContext;
    if (correctedContext != null && correctedContext.mounted) {
      await Scrollable.ensureVisible(
        correctedContext,
        alignment: 0.42,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  bool _handleUserScroll(UserScrollNotification notification) {
    _resumeFollowingTimer?.cancel();
    if (notification.direction != ScrollDirection.idle) {
      _followingPaused = true;
      return false;
    }
    _resumeFollowingTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      _followingPaused = false;
      _scheduleActiveSegmentScroll();
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final segments = controller.document!.segments;
    final colors = Theme.of(context).colorScheme;
    return NotificationListener<UserScrollNotification>(
      onNotification: _handleUserScroll,
      child: ListView.builder(
        key: const ValueKey('transcript_list'),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          hazeScreenInset,
          12,
          hazeScreenInset,
          24,
        ),
        itemCount: segments.length,
        itemBuilder: (context, index) {
          final segment = segments[index];
          final isActive = segment.index == controller.activeSegment?.index;
          final startsParagraph =
              index == 0 ||
              segments[index - 1].paragraphIndex != segment.paragraphIndex;
          final tile = ListTile(
            selected: isActive,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Text(
              _formatTimestamp(segment.startMs),
              style: TextStyle(
                color: isActive ? hazeGlassInk : colors.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            title: Text(
              segment.text,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                height: 1.35,
              ),
            ),
            subtitle:
                segment.speaker == null &&
                    (!controller.showTranslation || segment.translation == null)
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (segment.speaker != null)
                        Text(
                          segment.speaker!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isActive
                                    ? hazeGlassInk.withValues(alpha: 0.76)
                                    : colors.onSurfaceVariant,
                              ),
                        ),
                      if (controller.showTranslation &&
                          segment.translation != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          segment.translation!,
                          style: TextStyle(
                            color: isActive ? hazeGlassInk : colors.secondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
            onTap: controller.hasSynchronizedTranscript
                ? () => controller.select(segment)
                : null,
          );
          return KeyedSubtree(
            key: _segmentKeys.putIfAbsent(segment.index, GlobalKey.new),
            child: Padding(
              key: ValueKey('transcript_segment_${segment.index}'),
              padding: EdgeInsets.only(
                top: startsParagraph && index > 0 ? 12 : 0,
                bottom: 4,
              ),
              child: isActive
                  ? GlassSurface(
                      blur: hazeControlGlassBlur,
                      tint: hazeControlGlassTint,
                      borderRadius: BorderRadius.circular(12),
                      child: tile,
                    )
                  : Material(color: Colors.transparent, child: tile),
            ),
          );
        },
      ),
    );
  }
}

String _repeatModeLabel(PlaybackRepeatMode mode) => switch (mode) {
  PlaybackRepeatMode.off => '顺序播放',
  PlaybackRepeatMode.sentence => '单句循环',
  PlaybackRepeatMode.paragraph => '段落循环',
  PlaybackRepeatMode.episode => '整集循环',
};

double _maximumMilliseconds(Duration duration) {
  return duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
}

Duration _displayDuration(
  PlaybackController controller,
  TranscriptDocument? transcript,
) {
  if (controller.duration > Duration.zero) return controller.duration;
  final episodeSeconds = controller.episode?.durationSeconds ?? 0;
  if (episodeSeconds > 0) return Duration(seconds: episodeSeconds);
  final segments = transcript?.segments;
  return segments == null || segments.isEmpty
      ? Duration.zero
      : Duration(milliseconds: segments.last.endMs);
}

double _positionMilliseconds(Duration position, double maximum) {
  return position.inMilliseconds.clamp(0, maximum.toInt()).toDouble();
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String _formatTimestamp(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
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
