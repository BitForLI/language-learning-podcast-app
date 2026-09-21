import 'package:flutter/material.dart';

import '../application/library_controller.dart';
import '../domain/podcast.dart';
import 'podcast_artwork.dart';

const _recommendedSubscriptions = [
  (
    title: 'Practical AI',
    subtitle: '实用 AI · 工程与行业动态',
    feedUrl: 'https://feeds.transistor.fm/practical-ai-machine-learning-data-science-llm',
  ),
  (
    title: 'The TED AI Show',
    subtitle: 'AI 与社会 · 深度访谈',
    feedUrl: 'https://feeds.acast.com/public/shows/6758564a102e6d4448d19589',
  ),
  (
    title: 'Latent Space',
    subtitle: 'AI 工程 · 模型与开发者生态',
    feedUrl: 'https://api.substack.com/feed/podcast/1084089.rss',
  ),
];

class AddSubscriptionSheet extends StatefulWidget {
  const AddSubscriptionSheet({super.key, required this.controller});

  final LibraryController controller;

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _searchController = TextEditingController();
  final _rssController = TextEditingController();
  List<PodcastSearchResult> _results = const [];
  bool _isSearching = false;
  bool _isAdding = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _rssController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final results = await widget.controller.search(query);
      if (mounted) setState(() => _results = results);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _add(String feedUrl) async {
    if (feedUrl.trim().isEmpty || _isAdding) return;
    setState(() {
      _isAdding = true;
      _error = null;
    });
    try {
      await widget.controller.add(feedUrl.trim());
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('添加播客', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Text('推荐播客', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            ..._recommendedSubscriptions.map(
              (podcast) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.podcasts_rounded),
                title: Text(podcast.title),
                subtitle: Text(podcast.subtitle),
                trailing: const Icon(Icons.add_circle_outline_rounded),
                onTap: _isAdding ? null : () => _add(podcast.feedUrl),
              ),
            ),
            const Divider(height: 28),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: '搜索 Apple Podcasts',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: '搜索',
                  onPressed: _isSearching ? null : _search,
                  icon: _isSearching
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._results
                  .take(8)
                  .map(
                    (result) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: PodcastArtwork(url: result.artworkUrl, size: 48),
                      title: Text(
                        result.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: result.author == null
                          ? null
                          : Text(
                              result.author!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: const Icon(Icons.add_circle_outline_rounded),
                      onTap: _isAdding ? null : () => _add(result.feedUrl),
                    ),
                  ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('或'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            TextField(
              controller: _rssController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: _add,
              decoration: const InputDecoration(
                labelText: 'RSS 地址',
                hintText: 'https://example.com/feed.xml',
                prefixIcon: Icon(Icons.rss_feed_rounded),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isAdding ? null : () => _add(_rssController.text),
              child: _isAdding
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('收藏这个播客'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
