import 'package:flutter/material.dart';
import 'package:multi_video/screens/components/button_go_back.dart';
import 'package:multi_video/screens/components/liveStream/live_network_safe_video.dart';

class LiveStreamLayout extends StatefulWidget {
  final List<String> videoUrls;

  const LiveStreamLayout({super.key, required this.videoUrls});

  @override
  State<LiveStreamLayout> createState() => _LiveStreamLayoutState();
}

class _LiveStreamLayoutState extends State<LiveStreamLayout> {
  int _mainVideoIndex = 0;
  bool _showDock = false;
  int _thumbnailStartIndex = 0;
  
  static const int maxTotalVideos = 3;

  void _setMainVideo(int index) {
    if (index != _mainVideoIndex) {
      setState(() {
        _mainVideoIndex = index;
        _showDock = false;
        _adjustThumbnailStartIndex();
      });
    }
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

  int get _previousThumbnailsCount {
    return _thumbnailStartIndex;
  }

  bool get _hasMoreThumbnails {
    return _remainingThumbnails > 0;
  }

  bool get _canGoBack {
    return _thumbnailStartIndex > 0;
  }

  void _toggleDock() {
    setState(() {
      _showDock = !_showDock;
    });
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
                      flex: _showDock ? 1 : 0,
                      child: _showDock ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const ButtonGoBack(),
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D3D3C),
                              borderRadius: BorderRadius.circular(35),
                            ),
                            child: Text(
                              'Câmera ${_mainVideoIndex + 1}',
                              style: const TextStyle(
                                color: Color(0xFFFFC501),
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 33),
                        ],
                      ) : const SizedBox.shrink(),
                    ),
                    // Main video area
                    Flexible(
                      flex: 4,
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: LiveNetworkSafeVideo(
                            key: ValueKey('main_video_${widget.videoUrls[_mainVideoIndex]}_$_mainVideoIndex'),
                            videoUrl: widget.videoUrls[_mainVideoIndex],
                            onTap: _toggleDock,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Optimized thumbnails with navigation
            if (widget.videoUrls.length > 1)
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.only(right: 4, top: 4, bottom: 4),
                  child: Column(
                    children: [
                      if (_canGoBack) ...[
                        GestureDetector(
                          onTap: _previousThumbnails,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '+$_previousThumbnailsCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_up,
                                    color: Color(0xFFFFC501), size: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                      ..._visibleThumbnailIndices.map((originalIndex) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: GestureDetector(
                              onTap: () => _setMainVideo(originalIndex),
                              child: ClipRRect(
                                child: LiveNetworkSafeVideo(
                                  key: ValueKey('thumbnail_video_${widget.videoUrls[originalIndex]}_$originalIndex'),
                                  videoUrl: widget.videoUrls[originalIndex],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_hasMoreThumbnails) ...[
                        GestureDetector(
                          onTap: _nextThumbnails,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.keyboard_arrow_down,
                                  color: Color(0xFFFFC501), size: 24),
                                Text(
                                  '+$_remainingThumbnails',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}