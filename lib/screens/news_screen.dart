// lib/screens/news_screen.dart
import 'package:flutter/material.dart';
import 'package:test1/models/news_post.dart';
import 'package:test1/services/vk_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final VkApiService _vkService = VkApiService();
  List<NewsPost> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      const ownerId = 221562447;
      final rawPosts = await _vkService.fetchWallPosts(ownerId: ownerId);
      final posts = rawPosts.map((p) => NewsPost.fromJson(p)).toList();
      if (!mounted) return; // проверка перед setState
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось открыть ссылку: $url'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}.${date.month}.${date.year} в ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildVideoSection(NewsPost post) {
    return Column(
      children: post.videos.map((video) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.play_circle_filled, size: 40, color: Color(0xFF4CAF50)),
            title: Text(
              video.title,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Длительность: ${_formatDuration(video.duration)}',
              style: const TextStyle(color: Color(0xFFBDBDBD)),
            ),
            onTap: () => _launchUrl(post.postUrl),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPollSection(List<PollAttachment> polls) {
    return Column(
      children: polls.map((poll) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(poll.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...poll.answers.map((answer) {
                  final percentage = answer.rate.toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(answer.text)),
                            Text('$percentage% (${answer.votes})'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: answer.rate / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Text('Всего голосов: ${poll.votes}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLinkSection(List<LinkAttachment> links) {
    return Column(
      children: links.map((link) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.link, color: Colors.blue),
            title: Text(link.title),
            subtitle: Text(link.caption ?? link.url),
            onTap: () => _launchUrl(link.url),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOpenPostButton(NewsPost post) {
    return TextButton.icon(
      onPressed: () => _launchUrl(post.postUrl),
      icon: const Icon(Icons.open_in_browser, size: 18, color: Color(0xFF4CAF50)), // зелёный
      label: const Text(
        'Открыть в VK',
        style: TextStyle(color: Color(0xFF4CAF50)), // зелёный текст
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> photoUrls, List<double> aspectRatios) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();

    final ratios = aspectRatios.isEmpty
        ? List.filled(photoUrls.length, 1.0)
        : aspectRatios;

    return _PhotoGallery(
      photoUrls: photoUrls,
      aspectRatios: ratios,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7B0D8F)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadNews();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNews,
      color: const Color(0xFF7B0D8F),
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.text.isNotEmpty)
                    Text(post.text, style: const TextStyle(fontSize: 16, color: Colors.white)),

                  if (post.photoUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPhotoGallery(post.photoUrls, post.photoAspectRatios),
                  ],

                  if (post.videos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildVideoSection(post),
                  ],

                  if (post.polls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPollSection(post.polls),
                  ],

                  if (post.links.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildLinkSection(post.links),
                  ],

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(post.date),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      _buildOpenPostButton(post),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----- _PhotoGallery (без изменений, но проверки mounted добавлены при необходимости) -----
class _PhotoGallery extends StatefulWidget {
  final List<String> photoUrls;
  final List<double> aspectRatios;

  const _PhotoGallery({
    required this.photoUrls,
    required this.aspectRatios,
  });

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  late PageController _pageController;
  int _currentPage = 0;
  double _currentHeight = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateHeight(double width) {
    if (width == 0) return;
    final ratio = widget.aspectRatios[_currentPage];
    final newHeight = width / ratio;
    if (_currentHeight != newHeight) {
      setState(() {
        _currentHeight = newHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateHeight(availableWidth);
            });
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _currentHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.photoUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateHeight(availableWidth);
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Image.network(
                      widget.photoUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF7B0D8F)));
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 100);
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
        if (widget.photoUrls.length > 1) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.photoUrls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentPage ? const Color(0xFF4CAF50) : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}