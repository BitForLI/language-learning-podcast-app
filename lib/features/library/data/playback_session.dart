import '../domain/podcast.dart';

class PlaybackSession {
  const PlaybackSession({
    required this.episode,
    required this.positionMs,
    required this.speed,
    this.podcastTitle,
    this.artworkUrl,
  });

  factory PlaybackSession.fromJson(Map<String, dynamic> json) {
    return PlaybackSession(
      episode: Episode.fromJson(json['episode'] as Map<String, dynamic>),
      positionMs: json['position_ms'] as int? ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 1,
      podcastTitle: json['podcast_title'] as String?,
      artworkUrl: json['artwork_url'] as String?,
    );
  }

  final Episode episode;
  final int positionMs;
  final double speed;
  final String? podcastTitle;
  final String? artworkUrl;

  Map<String, dynamic> toJson() => {
    'episode': episode.toJson(),
    'position_ms': positionMs,
    'speed': speed,
    'podcast_title': podcastTitle,
    'artwork_url': artworkUrl,
  };
}
