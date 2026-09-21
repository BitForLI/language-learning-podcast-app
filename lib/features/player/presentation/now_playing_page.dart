part of 'player_screen.dart';

class _NowPlayingPage extends StatelessWidget {
  const _NowPlayingPage({
    required this.controller,
    required this.transcriptController,
    required this.onSelectRepeat,
    required this.onShowTranscript,
    required this.onShowQueue,
    this.onShowProgress,
    this.onClose,
  });

  final PlaybackController controller;
  final TranscriptController transcriptController;
  final ValueChanged<PlaybackRepeatMode> onSelectRepeat;
  final VoidCallback onShowTranscript;
  final VoidCallback onShowQueue;
  final VoidCallback? onShowProgress;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final episode = controller.episode!;
    final duration = _displayDuration(
      controller,
      transcriptController.document,
    );
    final maximum = _maximumMilliseconds(duration);
    final position = _positionMilliseconds(controller.position, maximum);
    final remaining = duration > controller.position
        ? duration - controller.position
        : Duration.zero;
    const foreground = Color(0xFF202832);
    const secondary = Color(0xFF536171);
    final paragraphNavigation =
        controller.repeatMode == PlaybackRepeatMode.paragraph;
    final canGoPrevious = paragraphNavigation
        ? transcriptController.canSelectPreviousParagraph
        : transcriptController.canSelectPrevious;
    final canGoNext = paragraphNavigation
        ? transcriptController.canSelectNextParagraph
        : transcriptController.canSelectNext;
    final previousLabel = paragraphNavigation ? '上一段' : '上一句';
    final nextLabel = paragraphNavigation ? '下一段' : '下一句';
    final previousAction = paragraphNavigation
        ? transcriptController.selectPreviousParagraph
        : transcriptController.selectPrevious;
    final nextAction = paragraphNavigation
        ? transcriptController.selectNextParagraph
        : transcriptController.selectNext;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller.artworkUrl case final artworkUrl?
            when artworkUrl.isNotEmpty)
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: Image.network(
              artworkUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 52, sigmaY: 52),
          child: ColoredBox(
            color: const Color(0xFFD6DADD).withValues(alpha: 0.78),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xA8EEEFF0), Color(0xC8D5DBE0), Color(0xDDB5C2CE)],
              stops: [0, 0.52, 1],
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 680;
            final artworkSize = (constraints.maxWidth - (compact ? 150 : 100))
                .clamp(170.0, compact ? 225.0 : 286.0);
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  hazeScreenInset,
                  compact ? 0 : 4,
                  hazeScreenInset,
                  hazeScreenInset,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 48,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Container(
                            width: 48,
                            height: 5,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: foreground.withValues(alpha: 0.48),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: '返回 BANK',
                              onPressed: onClose,
                              color: foreground,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 0 : 8),
                    KeyedSubtree(
                      key: const ValueKey('player_artwork'),
                      child: _PlayerArtwork(
                        url: controller.artworkUrl,
                        size: artworkSize,
                      ),
                    ),
                    SizedBox(height: compact ? 2 : 8),
                    Row(
                      key: const ValueKey('player_secondary_tools'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PlaybackModeButton(
                          mode: controller.repeatMode,
                          onSelected: onSelectRepeat,
                        ),
                        const SizedBox(width: 44),
                        _PlainPlayerButton(
                          tooltip: '播放队列',
                          icon: Icons.queue_music_rounded,
                          onPressed: onShowQueue,
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 4 : 10),
                    Align(
                      key: const ValueKey('player_episode_title'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        episode.title,
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                        ),
                      ),
                    ),
                    if (controller.podcastTitle != null) ...[
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          controller.podcastTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: secondary),
                        ),
                      ),
                    ],
                    SizedBox(height: compact ? 10 : 16),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: foreground,
                        inactiveTrackColor: Colors.black26,
                        thumbColor: foreground,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: position,
                        max: maximum,
                        onChanged: duration == Duration.zero
                            ? null
                            : (value) => controller.seek(
                                Duration(milliseconds: value.round()),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(controller.position),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: secondary),
                          ),
                          Text(
                            '-${_formatDuration(remaining)}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: secondary),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(height: compact ? 2 : 6),
                    SizedBox(
                      height: hazeBottomPanelHeight,
                      child: GlassSurface(
                        key: const ValueKey('player_action_glass'),
                        blur: hazeControlGlassBlur,
                        tint: hazeControlGlassTint,
                        borderRadius: BorderRadius.circular(30),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: compact ? 58 : 62,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _SpeedButton(controller: controller),
                                    _TransportButton(
                                      tooltip: previousLabel,
                                      onPressed: canGoPrevious
                                          ? previousAction
                                          : null,
                                      icon: Icons.skip_previous_rounded,
                                    ),
                                    _PlayPauseButton(
                                      controller: controller,
                                      bare: true,
                                    ),
                                    _TransportButton(
                                      tooltip: nextLabel,
                                      onPressed: canGoNext ? nextAction : null,
                                      icon: Icons.skip_next_rounded,
                                    ),
                                  ],
                                ),
                              ),
                              MainNavigationRow(
                                key: const ValueKey('player_main_navigation'),
                                onProgress: onShowProgress,
                                onLibrary: onClose,
                                onTranscript: onShowTranscript,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.controller});

  final PlaybackController controller;

  @override
  Widget build(BuildContext context) {
    final speed = controller.speed == controller.speed.roundToDouble()
        ? controller.speed.toInt().toString()
        : controller.speed.toString();
    return PopupMenuButton<double>(
      tooltip: '播放速度',
      initialValue: controller.speed,
      onSelected: controller.setSpeed,
      itemBuilder: (context) => const [0.75, 1.0, 1.25, 1.5, 2.0]
          .map(
            (value) => CheckedPopupMenuItem(
              value: value,
              checked: controller.speed == value,
              child: Text('$value×'),
            ),
          )
          .toList(),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: Text(
            '$speed×',
            style: const TextStyle(
              color: Color(0xFF202832),
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaybackModeButton extends StatelessWidget {
  const _PlaybackModeButton({required this.mode, required this.onSelected});

  final PlaybackRepeatMode mode;
  final ValueChanged<PlaybackRepeatMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '切换播放方式',
      onPressed: () => onSelected(_nextRepeatMode(mode)),
      iconSize: 30,
      color: const Color(0xFF202832),
      icon: Icon(_repeatModeIcon(mode)),
    );
  }
}

class _PlainPlayerButton extends StatelessWidget {
  const _PlainPlayerButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 30,
      color: const Color(0xFF202832),
      icon: Icon(icon),
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 32,
      color: const Color(0xFF202832),
      disabledColor: const Color(0xFF202832).withValues(alpha: 0.28),
      icon: Icon(icon),
    );
  }
}

IconData _repeatModeIcon(PlaybackRepeatMode mode) => switch (mode) {
  PlaybackRepeatMode.sentence => Icons.repeat_one_rounded,
  PlaybackRepeatMode.paragraph => Icons.format_align_left_rounded,
  PlaybackRepeatMode.episode => Icons.all_inclusive_rounded,
  PlaybackRepeatMode.off => Icons.repeat_rounded,
};

PlaybackRepeatMode _nextRepeatMode(PlaybackRepeatMode mode) => switch (mode) {
  PlaybackRepeatMode.off => PlaybackRepeatMode.sentence,
  PlaybackRepeatMode.sentence => PlaybackRepeatMode.paragraph,
  PlaybackRepeatMode.paragraph => PlaybackRepeatMode.episode,
  PlaybackRepeatMode.episode => PlaybackRepeatMode.sentence,
};

class _PlayerArtwork extends StatelessWidget {
  const _PlayerArtwork({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: colors.secondaryContainer,
      child: SizedBox.square(
        dimension: size,
        child: Icon(
          Icons.podcasts_rounded,
          size: size * 0.34,
          color: colors.onSecondaryContainer,
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: url == null || url!.isEmpty
            ? fallback
            : Image.network(
                url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }
}
