import 'package:flutter/material.dart';
import 'package:multi_video/screens/components/dock.dart';
import 'package:multi_video/screens/components/network_safe_video.dart';

class MultiVideoLayout extends StatefulWidget {
  final List<String> videoUrls;

  const MultiVideoLayout({super.key, required this.videoUrls});

  @override
  State<MultiVideoLayout> createState() => _MultiVideoLayoutState();
}

class _MultiVideoLayoutState extends State<MultiVideoLayout> {
  int _mainVideoIndex = 0;
  bool _showDock = false;
  int _thumbnailStartIndex = 0;
  
  static const int maxTotalVideos = 3;

  void _setMainVideo(int index) {
    setState(() {
      _mainVideoIndex = index;
      _showDock = false;
      _adjustThumbnailStartIndex();
    });
  }

  void _toggleDock() {
    setState(() {
      _showDock = !_showDock;
    });
  }

  void _adjustThumbnailStartIndex() {
    final availableIndices = _getAvailableIndices();
    if (_thumbnailStartIndex >= availableIndices.length) {
      _thumbnailStartIndex = 0;
    }
  }

  int get _maxVisibleThumbnails {
    return maxTotalVideos - 1; // 1 for main video
  }

  void _nextThumbnails() {
    setState(() {
      final availableIndices = _getAvailableIndices();
      final maxThumbnailsToShow = _maxVisibleThumbnails;
      if (_thumbnailStartIndex + maxThumbnailsToShow < availableIndices.length) {
        _thumbnailStartIndex += maxThumbnailsToShow;
      }
    });
  }

  void _previousThumbnails() {
    setState(() {
      if (_thumbnailStartIndex > 0) {
        final maxThumbnailsToShow = _maxVisibleThumbnails;
        _thumbnailStartIndex = (_thumbnailStartIndex - maxThumbnailsToShow).clamp(0, double.infinity).toInt();
      }
    });
  }

  List<int> _getAvailableIndices() {
    List<int> indices = List.generate(widget.videoUrls.length, (index) => index);
    indices.removeAt(_mainVideoIndex);
    return indices;
  }

  List<int> get _visibleThumbnailIndices {
    final availableIndices = _getAvailableIndices();
    final maxThumbnailsToShow = _maxVisibleThumbnails;
    final endIndex = (_thumbnailStartIndex + maxThumbnailsToShow).clamp(0, availableIndices.length);
    return availableIndices.sublist(_thumbnailStartIndex, endIndex);
  }

  int get _remainingThumbnails {
    final availableIndices = _getAvailableIndices();
    final maxThumbnailsToShow = _maxVisibleThumbnails;
    final remaining = availableIndices.length - _thumbnailStartIndex - maxThumbnailsToShow;
    return remaining > 0 ? remaining : 0;
  }

  bool get _hasMoreThumbnails {
    return _remainingThumbnails > 0;
  }

  bool get _canGoBack {
    return _thumbnailStartIndex > 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrls.isEmpty) {
      return const Center(child: Text('No videos available'));
    }

    return Stack(
      children: [
        Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.all(4),
            child: Column(
              children: [
                Expanded(
                  flex: _showDock ? 3 : 4,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Stack(
                        children: [
                          NetworkSafeVideo(
                            key: ValueKey('main_video_${widget.videoUrls[_mainVideoIndex]}_$_mainVideoIndex'),
                            videoUrl: widget.videoUrls[_mainVideoIndex],
                            onTap: _toggleDock,
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LIVE ${_mainVideoIndex + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showDock)
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey, width: 1),
                      ),
                      child: const Dock(),
                    ),
                  ),
              ],
            ),
          ),
        ),
            if (widget.videoUrls.length > 1)
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.only(right: 4, top: 4, bottom: 4),
                  child: Column(
                    children: [
                      if (_canGoBack)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onTap: _previousThumbnails,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Icon(Icons.keyboard_arrow_up, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ..._visibleThumbnailIndices.map((originalIndex) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: GestureDetector(
                              onTap: () => _setMainVideo(originalIndex),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey, width: 2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: NetworkSafeVideo(
                                    key: ValueKey('thumbnail_video_${widget.videoUrls[originalIndex]}_$originalIndex'),
                                    videoUrl: widget.videoUrls[originalIndex],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_hasMoreThumbnails)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onTap: _nextThumbnails,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.orange, width: 2),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                                    Text(
                                      '+$_remainingThumbnails',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
        if (_showDock)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }
}