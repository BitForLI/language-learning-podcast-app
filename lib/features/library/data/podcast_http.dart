import 'dart:convert';
import 'dart:io';

import '../domain/podcast.dart';
import 'podcast_repository.dart';

Future<List<PodcastSearchResult>> searchApplePodcasts(String query) async {
  final text = query.trim();
  if (text.isEmpty) return const [];
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': text,
      'media': 'podcast',
      'entity': 'podcast',
      'limit': '20',
    });
    final response = await (await client.getUrl(uri)).close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      throw PodcastRepositoryException(
        'Apple Podcasts 搜索失败（${response.statusCode}）',
      );
    }
    final payload = jsonDecode(await response.transform(utf8.decoder).join());
    final results = payload is Map<String, dynamic>
        ? payload['results'] as List<dynamic>? ?? const []
        : const <dynamic>[];
    return results
        .whereType<Map<String, dynamic>>()
        .where(
          (item) =>
              item['feedUrl'] is String && item['collectionName'] is String,
        )
        .map(
          (item) => PodcastSearchResult(
            title: item['collectionName'] as String,
            feedUrl: item['feedUrl'] as String,
            author: item['artistName'] as String?,
            artworkUrl:
                item['artworkUrl600'] as String? ??
                item['artworkUrl100'] as String?,
          ),
        )
        .toList();
  } on PodcastRepositoryException {
    rethrow;
  } on SocketException catch (error) {
    throw PodcastRepositoryException('无法搜索播客：${error.message}');
  } finally {
    client.close(force: true);
  }
}

Future<String> fetchTranscriptText(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !const {'http', 'https'}.contains(uri.scheme)) {
    throw const PodcastRepositoryException('字幕地址无效');
  }
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final response = await (await client.getUrl(uri)).close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      throw PodcastRepositoryException('无法获取字幕（${response.statusCode}）');
    }
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close(force: true);
  }
}
