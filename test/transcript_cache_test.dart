import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:listen/features/library/domain/podcast.dart';
import 'package:listen/features/player/data/transcript_audio_store.dart';
import 'package:listen/features/player/data/transcript_cache.dart';

void main() {
  late Directory temporary;
  late TranscriptAudioStore audioStore;
  late TranscriptCache cache;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('listen-cache-test-');
    audioStore = TranscriptAudioStore(
      directory: Directory('${temporary.path}/audio'),
    );
    cache = TranscriptCache(
      version: 6,
      directory: Directory('${temporary.path}/transcripts'),
    );
  });

  tearDown(() => temporary.delete(recursive: true));

  test('returns only completed transcripts with retained audio', () async {
    final download = File('${temporary.path}/episode.mp3');
    await download.writeAsBytes([1, 2, 3]);
    final audioKey = await audioStore.retain(download, episodeId: 4);
    final document = _document(audioKey);

    await cache.write(document, complete: false);
    expect(await cache.read(4, audioStore: audioStore), isNull);

    await cache.write(document, complete: true);
    final restored = await cache.read(4, audioStore: audioStore);
    expect(restored?.segments.single.text, 'A cached sentence.');
    expect(restored?.audioKey, audioKey);
  });

  test('rejects completed transcripts when their audio is missing', () async {
    await cache.write(_document('episode-4-999.mp3'), complete: true);

    expect(await cache.read(4, audioStore: audioStore), isNull);
  });
}

TranscriptDocument _document(String audioKey) => TranscriptDocument(
  episodeId: 4,
  language: 'en',
  source: 'android-v6-parakeet',
  audioKey: audioKey,
  segments: const [
    TranscriptSegment(
      index: 0,
      startMs: 100,
      endMs: 900,
      text: 'A cached sentence.',
      paragraphIndex: 0,
    ),
  ],
);
