import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/widgets/glass_surface.dart';
import '../../library/data/podcast_repository.dart';
import '../../library/domain/podcast.dart';
import '../application/playback_controller.dart';
import '../application/playback_engine.dart';
import '../application/transcript_controller.dart';
import '../data/subtitle_exporter.dart';

part 'now_playing_page.dart';
part 'playback_queue_sheet.dart';
part 'transcript_reading_page.dart';
part 'transcript_controls.dart';
part 'transcript_list.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({
    super.key,
    required this.controller,
    required this.transcriptController,
    required this.podcastRepository,
    this.transcriptOnly = false,
    this.onShowProgress,
    this.onShowTranscript,
    this.onClose,
  });

  final PlaybackController controller;
  final TranscriptController transcriptController;
  final PodcastRepository podcastRepository;
  final bool transcriptOnly;
  final VoidCallback? onShowProgress;
  final VoidCallback? onShowTranscript;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: controller.episode == null
          ? Colors.transparent
          : const Color(0xFFD8DDE2),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.episode == null) return const _EmptyPlayer();
          return _ActivePlayer(
            controller: controller,
            transcriptController: transcriptController,
            podcastRepository: podcastRepository,
            transcriptOnly: transcriptOnly,
            onShowProgress: onShowProgress,
            onShowTranscript: onShowTranscript,
            onClose: onClose,
          );
        },
      ),
    );
  }
}

class _EmptyPlayer extends StatelessWidget {
  const _EmptyPlayer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.headphones_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text('尚未播放', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('从播客的单集列表中选择一集。'),
          ],
        ),
      ),
    );
  }
}

class _ActivePlayer extends StatefulWidget {
  const _ActivePlayer({
    required this.controller,
    required this.transcriptController,
    required this.podcastRepository,
    required this.transcriptOnly,
    this.onShowProgress,
    this.onShowTranscript,
    this.onClose,
  });

  final PlaybackController controller;
  final TranscriptController transcriptController;
  final PodcastRepository podcastRepository;
  final bool transcriptOnly;
  final VoidCallback? onShowProgress;
  final VoidCallback? onShowTranscript;
  final VoidCallback? onClose;

  @override
  State<_ActivePlayer> createState() => _ActivePlayerState();
}

class _ActivePlayerState extends State<_ActivePlayer> {
  int? _autoStartedEpisodeId;
  Offset? _pullDownStart;
  bool _closeArmed = false;

  @override
  void initState() {
    super.initState();
    widget.transcriptController.addListener(_maybeStartEnglishTranscription);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeStartEnglishTranscription();
    });
  }

  Future<void> _selectRepeat(PlaybackRepeatMode mode) async {
    try {
      await widget.controller.setRepeatMode(mode);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _startPullDown(PointerDownEvent event, double maximumStartY) {
    if (widget.onClose == null || event.localPosition.dy > maximumStartY) {
      _pullDownStart = null;
      return;
    }
    _pullDownStart = event.localPosition;
    _closeArmed = false;
  }

  void _updatePullDown(PointerMoveEvent event) {
    final start = _pullDownStart;
    if (_closeArmed || start == null || widget.onClose == null) return;
    final movement = event.localPosition - start;
    if (movement.dy < 56 || movement.dy < movement.dx.abs() * 1.2) return;
    _closeArmed = true;
  }

  void _endPullDown(PointerEvent event) {
    final shouldClose = _closeArmed;
    _pullDownStart = null;
    _closeArmed = false;
    if (shouldClose && widget.onClose != null) widget.onClose!();
  }

  void _cancelPullDown(PointerEvent event) {
    _pullDownStart = null;
    _closeArmed = false;
  }

  void _maybeStartEnglishTranscription() {
    final episodeId = widget.controller.episode?.id;
    final transcript = widget.transcriptController;
    if (!widget.transcriptOnly ||
        episodeId == null ||
        transcript.isLoading ||
        transcript.isTranscribing ||
        transcript.hasSynchronizedTranscript ||
        _autoStartedEpisodeId == episodeId) {
      return;
    }
    _autoStartedEpisodeId = episodeId;
    unawaited(transcript.transcribe(language: 'en'));
  }

  void _showPlaybackQueue() {
    final episode = widget.controller.episode;
    if (episode == null) return;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      builder: (context) => _PlaybackQueueSheet(
        repository: widget.podcastRepository,
        currentEpisode: episode,
        podcastTitle: widget.controller.podcastTitle,
        artworkUrl: widget.controller.artworkUrl,
        onPlay: (nextEpisode) {
          Navigator.pop(context);
          unawaited(
            widget.controller.loadEpisode(
              nextEpisode,
              fromPodcast: widget.controller.podcastTitle,
              fromArtworkUrl: widget.controller.artworkUrl,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.transcriptController.removeListener(_maybeStartEnglishTranscription);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transcriptOnly) {
      return KeyedSubtree(
        key: const ValueKey('transcript_only_page'),
        child: _TranscriptReadingPage(
          controller: widget.controller,
          transcriptController: widget.transcriptController,
          onSelectRepeat: _selectRepeat,
          onShowPlayer: widget.onClose ?? () {},
        ),
      );
    }
    final maximumCloseGestureStartY = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      top: false,
      bottom: false,
      child: Listener(
        key: const ValueKey('player_pull_down_handle'),
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) =>
            _startPullDown(event, maximumCloseGestureStartY),
        onPointerMove: _updatePullDown,
        onPointerUp: _endPullDown,
        onPointerCancel: _cancelPullDown,
        child: ListenableBuilder(
          listenable: widget.transcriptController,
          builder: (context, child) => _NowPlayingPage(
            controller: widget.controller,
            transcriptController: widget.transcriptController,
            onSelectRepeat: _selectRepeat,
            onShowTranscript: widget.onShowTranscript ?? () {},
            onShowQueue: _showPlaybackQueue,
            onShowProgress: widget.onShowProgress,
            onClose: widget.onClose,
          ),
        ),
      ),
    );
  }
}
