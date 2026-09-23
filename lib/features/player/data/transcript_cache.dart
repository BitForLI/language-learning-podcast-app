import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../library/domain/podcast.dart';
import 'transcript_audio_store.dart';

/// Persists completed and in-progress on-device transcripts.
class TranscriptCache {
  TranscriptCache({required this.version, this.directory});

  final int version;
  final Directory? directory;
  Directory? _directory;

  Future<TranscriptDocument?> read(
    int episodeId, {
    required TranscriptAudioStore audioStore,
  }) async {
    final file = await _file(episodeId);
    if (!await file.exists()) return null;
    try {
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (data['asr_cache_version'] != version ||
          data['asr_complete'] != true) {
        return null;
      }
      final document = TranscriptDocument.fromJson(data);
      final audioKey = document.audioKey;
      if (audioKey == null || await audioStore.resolve(audioKey) == null) {
        return null;
      }
      return document;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    TranscriptDocument document, {
    required bool complete,
  }) async {
    final file = await _file(document.episodeId);
    await file.writeAsString(
      jsonEncode(_toJson(document, complete: complete)),
      flush: true,
    );
  }

  Future<File> _file(int episodeId) async {
    final root = _directory ??=
        directory ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}/transcripts',
        );
    await root.create(recursive: true);
    return File('${root.path}/episode-$episodeId.json');
  }

  Map<String, dynamic> _toJson(
    TranscriptDocument document, {
    required bool complete,
  }) => {
    'asr_cache_version': version,
    'asr_complete': complete,
    'episode_id': document.episodeId,
    'language': document.language,
    'source': document.source,
    'target_language': document.targetLanguage,
    'translation_source': document.translationSource,
    'audio_key': document.audioKey,
    'segments': document.segments
        .map(
          (segment) => {
            'index': segment.index,
            'start_ms': segment.startMs,
            'end_ms': segment.endMs,
            'text': segment.text,
            'speaker': segment.speaker,
            'paragraph_index': segment.paragraphIndex,
            'translation': segment.translation,
          },
        )
        .toList(),
  };
}
