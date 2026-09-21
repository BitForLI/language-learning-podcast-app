import 'package:flutter/material.dart';

class PodcastArtwork extends StatelessWidget {
  const PodcastArtwork({super.key, required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: const Icon(Icons.podcasts_rounded),
    );
    if (url == null || url!.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: fallback,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
