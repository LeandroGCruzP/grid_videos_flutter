import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:multi_video/screens/components/button_go_back.dart';
import 'package:multi_video/screens/controllers/sync_video_better_player_controller.dart';

import 'sync_dock.dart';

class SyncVideoLayout extends StatefulWidget {
  final List<String> videoUrls;

  const SyncVideoLayout({super.key, required this.videoUrls});

  @override
  State<SyncVideoLayout> createState() =>
      _SyncVideoLayoutState();
}

class _SyncVideoLayoutState extends State<SyncVideoLayout> {
  final List<SyncVideoBetterPlayerController?> _controllers = [];
  int _mainVideoIndex = 0;
  bool _showDock = false;
  bool _allControllersReady = false;
  int _thumbnailStartIndex = 0;
  
  static const int maxTotalVideos = 3;

  @override
  void initState() {
    super.initState();
    // Useful to avoid index errors and make it easier to manage controllers as videos are loaded
    for (int i = 0; i < widget.videoUrls.length; i++) {
      _controllers.add(null);
    }
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    for (int i = 0; i < widget.videoUrls.length; i++) {
      if (_controllers[i] == null) {
        _createOptimizedController(i);
      }
    }
    _checkIfAllControllersReady();
  }

  void _createOptimizedController(int index) {
    try {
      final controller = SyncVideoBetterPlayerController(widget.videoUrls[index]);

      if (mounted) {
        setState(() {
          _controllers[index] = controller;
        });

        // Check if all controllers are ready periodically
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }

          _checkIfAllControllersReady();

          if (_allControllersReady || timer.tick > 50) {
            // Stop after 10 seconds
            timer.cancel();
          }
        });
      }
    } catch (e) {
      debugPrint(
          '❌ 🎥 Error creating optimized controller for video $index: $e');
    }
  }

  void _checkIfAllControllersReady() {
    final allReady = _controllers
        .every((controller) => controller != null && controller.isReady);

    if (allReady && !_allControllersReady) {
      setState(() {
        _allControllersReady = true;
      });
      _synchronizeAllVideosStart();
    }
  }

  Future<void> _synchronizeAllVideosStart() async {
    // Controllers are already configured to start at position 0
    for (final controller in _controllers) {
      if (controller != null && controller.isReady) {
        try {
          await controller.controller.seekTo(Duration.zero);
        } catch (e) {
          debugPrint('❌ 🎥 Error seeking to start: $e');
        }
      }
    }
  }

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

  bool get _hasMoreThumbnails {
    return _remainingThumbnails > 0;
  }

  bool get _canGoBack {
    return _thumbnailStartIndex > 0;
  }

  List<BetterPlayerController> get _allControllers {
    return _controllers
        .where((controller) => controller != null && controller.isReady)
        .map((controller) => controller!.controller)
        .toList();
  }

  void _toggleDock() {
    setState(() {
      _showDock = !_showDock;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  Widget _buildOptimizedVideo(int index, {bool isMain = false}) {
    final controller = _controllers[index];

    if (controller == null || !controller.isReady) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return BetterPlayer(controller: controller.controller);
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
                          border: Border.all(color: const Color.fromARGB(31, 88, 88, 88), width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: _toggleDock,
                                child: _buildOptimizedVideo(_mainVideoIndex,
                                    isMain: true),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'VIDEO ${_mainVideoIndex + 1}',
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
                            border: Border.all(color: const Color.fromARGB(31, 88, 88, 88), width: 2),
                          ),
                          child: SyncDock(
                            key:
                                ValueKey('sync_dock_${_allControllers.length}'),
                            mainController:
                                _controllers[_mainVideoIndex]?.isReady == true
                                    ? _controllers[_mainVideoIndex]!.controller
                                    : null,
                            allControllers: _allControllers,
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
                      ],
                      ..._visibleThumbnailIndices.map((originalIndex) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: GestureDetector(
                              onTap: () => _setMainVideo(originalIndex),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color.fromARGB(31, 88, 88, 88), width: 2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: _buildOptimizedVideo(originalIndex),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_hasMoreThumbnails) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onTap: _nextThumbnails,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color.fromARGB(31, 88, 88, 88), width: 2),
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
                      ]
                    ]
                  ),
                ),
              ),
          ],
        ),
        if (_showDock)
          const Positioned(
            top: 16,
            left: 16,
            child: ButtonGoBack()
          ),
      ],
    );
  }
}
