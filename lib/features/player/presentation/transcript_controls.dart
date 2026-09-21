part of 'player_screen.dart';

class _TranscriptBody extends StatelessWidget {
  const _TranscriptBody({required this.controller});

  final TranscriptController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final document = controller.document;
    if (document != null && document.segments.isNotEmpty) {
      return Column(
        children: [
          if (controller.needsAlignment)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(child: Text('旧字幕尚未匹配当前音频，暂不自动跟随。')),
                  TextButton(
                    onPressed: controller.isTranscribing
                        ? null
                        : controller.transcribe,
                    child: const Text('重新校准'),
                  ),
                ],
              ),
            ),
          if (controller.isTranscribing)
            _TranscriptionProgress(controller: controller),
          Expanded(child: _TranscriptList(controller: controller)),
        ],
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.tonalIcon(
            onPressed: controller.isTranscribing
                ? null
                : () => controller.transcribe(language: 'en'),
            icon: controller.isTranscribing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: const Text('转写英语'),
          ),
          if (controller.isTranscribing) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                value: (controller.transcriptionProgress ?? 0) <= 0
                    ? null
                    : controller.transcriptionProgress,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.transcriptionStatus ?? '正在准备转写…',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _TranscriptionProgress extends StatelessWidget {
  const _TranscriptionProgress({required this.controller});

  final TranscriptController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: (controller.transcriptionProgress ?? 0) <= 0
                ? null
                : controller.transcriptionProgress,
          ),
          const SizedBox(height: 6),
          Text(
            controller.transcriptionStatus ?? '正在生成字幕…',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReadingControls extends StatelessWidget {
  const _ReadingControls({
    required this.controller,
    required this.transcriptController,
    required this.onSelectRepeat,
  });

  final PlaybackController controller;
  final TranscriptController transcriptController;
  final ValueChanged<PlaybackRepeatMode> onSelectRepeat;

  @override
  Widget build(BuildContext context) {
    final duration = _displayDuration(
      controller,
      transcriptController.document,
    );
    final maximum = _maximumMilliseconds(duration);
    final position = _positionMilliseconds(controller.position, maximum);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        hazeScreenInset,
        0,
        hazeScreenInset,
        hazeScreenInset,
      ),
      child: SizedBox(
        height: 120,
        child: GlassSurface(
          key: const ValueKey('transcript_control_glass'),
          blur: hazeControlGlassBlur,
          tint: hazeControlGlassTint,
          borderRadius: BorderRadius.circular(28),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Color(0xFF202124)),
            child: IconTheme(
              data: const IconThemeData(color: Color(0xFF202124)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _SpeedButton(controller: controller),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 30,
                                  child: Slider(
                                    value: position,
                                    max: maximum,
                                    onChanged: duration == Duration.zero
                                        ? null
                                        : (value) => controller.seek(
                                            Duration(
                                              milliseconds: value.round(),
                                            ),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(controller.position),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ReadingModeButton(
                            mode: controller.repeatMode,
                            onSelected: onSelectRepeat,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 59,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _SentenceButton(
                            tooltip: '跳到上一句',
                            label: '上一句',
                            icon: Icons.skip_previous_rounded,
                            onPressed: transcriptController.canSelectPrevious
                                ? transcriptController.selectPrevious
                                : null,
                            foregroundColor: const Color(0xFF202124),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PlayPauseButton(
                                controller: controller,
                                compact: true,
                                bare: true,
                              ),
                              Text(
                                controller.playing ? '暂停' : '播放',
                                style: const TextStyle(fontSize: 11, height: 1),
                              ),
                            ],
                          ),
                          _SentenceButton(
                            tooltip: '跳到下一句',
                            label: '下一句',
                            icon: Icons.skip_next_rounded,
                            onPressed: transcriptController.canSelectNext
                                ? transcriptController.selectNext
                                : null,
                            foregroundColor: const Color(0xFF202124),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingModeButton extends StatelessWidget {
  const _ReadingModeButton({required this.mode, required this.onSelected});

  final PlaybackRepeatMode mode;
  final ValueChanged<PlaybackRepeatMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '切换播放方式',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onSelected(_nextRepeatMode(mode)),
        child: SizedBox(
          width: 92,
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_repeatModeIcon(mode), size: 19),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _repeatModeLabel(mode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.controller,
    this.compact = false,
    this.bare = false,
  });

  final PlaybackController controller;
  final bool compact;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final unavailable =
        controller.isLoading ||
        controller.processingState == EngineProcessingState.loading;
    final icon = controller.isLoading
        ? SizedBox.square(
            dimension: compact ? 24 : 30,
            child: const CircularProgressIndicator(strokeWidth: 3),
          )
        : Icon(
            controller.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          );
    if (bare) {
      return IconButton(
        tooltip: controller.playing ? '暂停' : '播放',
        iconSize: compact ? 32 : 38,
        padding: const EdgeInsets.all(8),
        onPressed: unavailable ? null : controller.togglePlayPause,
        icon: icon,
      );
    }
    return IconButton.filled(
      tooltip: controller.playing ? '暂停' : '播放',
      iconSize: compact ? 32 : 42,
      padding: EdgeInsets.all(compact ? 12 : 18),
      onPressed: unavailable ? null : controller.togglePlayPause,
      icon: icon,
    );
  }
}

class _SentenceButton extends StatelessWidget {
  const _SentenceButton({
    required this.tooltip,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.foregroundColor,
  });

  final String tooltip;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor:
              foregroundColor ?? Theme.of(context).colorScheme.onSurface,
          disabledForegroundColor: Theme.of(context).disabledColor,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            Text(label, style: const TextStyle(fontSize: 11, height: 1)),
          ],
        ),
      ),
    );
  }
}
