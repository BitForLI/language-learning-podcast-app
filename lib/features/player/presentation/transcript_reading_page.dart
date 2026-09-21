part of 'player_screen.dart';

class _TranscriptReadingPage extends StatelessWidget {
  const _TranscriptReadingPage({
    required this.controller,
    required this.transcriptController,
    required this.onSelectRepeat,
    required this.onShowPlayer,
  });

  final PlaybackController controller;
  final TranscriptController transcriptController;
  final ValueChanged<PlaybackRepeatMode> onSelectRepeat;
  final VoidCallback onShowPlayer;

  Future<void> _exportTranscript(
    BuildContext context,
    TranscriptDocument document,
  ) async {
    final renderBox = context.findRenderObject();
    final origin = renderBox is RenderBox && renderBox.hasSize
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null;
    try {
      await const SubtitleExporter().export(
        document,
        episodeTitle: controller.episode?.title ?? 'Listen 字幕',
        sharePositionOrigin: origin,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('字幕导出失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: transcriptController,
      builder: (context, child) {
        final document = transcriptController.document;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE7E8E9),
                Color(0xFFDDE1E5),
                Color(0xFFCBD4DC),
                Color(0xFFBECAD5),
              ],
              stops: [0, 0.30, 0.68, 1],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: '返回播放封面',
                        onPressed: onShowPlayer,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      if (document != null) ...[
                        const Icon(Icons.subtitles_rounded, size: 22),
                      ],
                      const Spacer(),
                      if (document != null)
                        IconButton(
                          tooltip: '导出字幕',
                          onPressed: () => _exportTranscript(context, document),
                          icon: const Icon(Icons.file_download_outlined),
                        ),
                      if (document != null &&
                          transcriptController.supportsOnDeviceTranscription)
                        IconButton(
                          tooltip: '重新生成字幕',
                          onPressed: transcriptController.isTranscribing
                              ? null
                              : transcriptController.transcribe,
                          icon: const Icon(Icons.auto_fix_high_rounded),
                        ),
                      if (document != null && document.targetLanguage == null)
                        IconButton(
                          tooltip: '生成中文对照',
                          onPressed: transcriptController.isTranslating
                              ? null
                              : transcriptController.translate,
                          icon: transcriptController.isTranslating
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.translate_rounded),
                        )
                      else if (document?.targetLanguage != null)
                        FilterChip(
                          selected: transcriptController.showTranslation,
                          onSelected: (_) =>
                              transcriptController.toggleTranslation(),
                          avatar: const Icon(Icons.translate_rounded, size: 18),
                          label: const Text('中英'),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _TranscriptBody(controller: transcriptController),
                ),
                if (document != null)
                  _ReadingControls(
                    controller: controller,
                    transcriptController: transcriptController,
                    onSelectRepeat: onSelectRepeat,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
