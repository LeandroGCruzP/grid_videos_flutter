import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:multi_video/screens/components/button_go_back.dart';
import 'package:multi_video/screens/components/syncVideo/button_download.dart';
import 'package:multi_video/screens/controllers/sync_video_better_player_controller.dart';

import 'sync_dock.dart';

class SyncVideoLayout extends StatefulWidget {
  final List<String> videoUrls;

  const SyncVideoLayout({super.key, required this.videoUrls});

  @override
  State<SyncVideoLayout> createState() => _SyncVideoLayoutState();
}

class _SyncVideoLayoutState extends State<SyncVideoLayout> {
  final List<SyncVideoBetterPlayerController?> _controllers = [];
  final Map<int, Duration> _videoDurations = {}; // Cache video durations
  int _mainVideoIndex = 0;
  bool _showDock = false;
  bool _allControllersReady = false;
  int _thumbnailStartIndex = 0;
  Duration _currentSyncTime = Duration.zero;
  Duration _maxKnownDuration = Duration.zero;

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
    // Initialize only the main video and first few thumbnails
    _createOptimizedController(_mainVideoIndex); // Main video

    final visibleIndices = _visibleThumbnailIndices;
    for (int i = 0; i < visibleIndices.length && i < maxTotalVideos - 1; i++) {
      _createOptimizedController(visibleIndices[i]);
    }

    _checkIfAllControllersReady();
  }

  void _createOptimizedController(int index) {
    try {
      final controller =
          SyncVideoBetterPlayerController(widget.videoUrls[index]);

      if (mounted) {
        setState(() {
          _controllers[index] = controller;
        });

        // Check if all controllers are ready periodically and cache duration
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }

          // Cache duration when available
          if (controller.isReady && !_videoDurations.containsKey(index)) {
            try {
              final videoController =
                  controller.controller.videoPlayerController;
              if (videoController?.value.duration != null) {
                final duration = videoController!.value.duration!;
                _videoDurations[index] = duration;

                // Update max known duration
                if (duration > _maxKnownDuration) {
                  _maxKnownDuration = duration;
                  debugPrint(
                      '📏 New max duration found: ${duration.inSeconds}s from video $index');
                }
              }
            } catch (e) {
              debugPrint('Error caching duration for video $index: $e');
            }
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

      // Ensure the new main video controller is loaded
      _ensureControllerLoaded(index);
      _manageControllerPool();

      // Load any new thumbnail controllers
      _loadVisibleThumbnailControllers();
    }
  }

  void _adjustThumbnailStartIndex() {
    final availableIndices = _getAvailableIndices();
    final maxThumbnailsToShow = _maxVisibleThumbnails;

    // Ensure the start index doesn't exceed bounds
    if (_thumbnailStartIndex >= availableIndices.length) {
      _thumbnailStartIndex = 0;
    }

    // If we're in the middle of pages and the current page would be empty
    // try to maintain the user's context by adjusting smartly
    final endIndex = (_thumbnailStartIndex + maxThumbnailsToShow)
        .clamp(0, availableIndices.length);
    if (_thumbnailStartIndex >= endIndex && availableIndices.isNotEmpty) {
      // Go to the last valid page
      _thumbnailStartIndex =
          ((availableIndices.length - 1) ~/ maxThumbnailsToShow) *
              maxThumbnailsToShow;
      _thumbnailStartIndex =
          _thumbnailStartIndex.clamp(0, availableIndices.length - 1);
    }
  }

  int get _maxVisibleThumbnails {
    return maxTotalVideos - 1; // 1 for main video
  }

  void _nextThumbnails() {
    setState(() {
      final availableIndices = _getAvailableIndices();
      final maxThumbnailsToShow = _maxVisibleThumbnails;
      if (_thumbnailStartIndex + maxThumbnailsToShow <
          availableIndices.length) {
        _thumbnailStartIndex += maxThumbnailsToShow;
      }
    });
    _loadVisibleThumbnailControllers();
    _manageControllerPool();

    // Sync newly visible controllers after a brief delay
    Timer(const Duration(milliseconds: 1000), () {
      _syncAllVisibleControllers();
    });
  }

  void _previousThumbnails() {
    setState(() {
      if (_thumbnailStartIndex > 0) {
        final maxThumbnailsToShow = _maxVisibleThumbnails;
        _thumbnailStartIndex = (_thumbnailStartIndex - maxThumbnailsToShow)
            .clamp(0, double.infinity)
            .toInt();
      }
    });
    _loadVisibleThumbnailControllers();
    _manageControllerPool();

    // Sync newly visible controllers after a brief delay
    Timer(const Duration(milliseconds: 1000), () {
      _syncAllVisibleControllers();
    });
  }

  List<int> _getAvailableIndices() {
    List<int> indices =
        List.generate(widget.videoUrls.length, (index) => index);
    indices.removeAt(_mainVideoIndex);
    return indices;
  }

  List<int> get _visibleThumbnailIndices {
    final availableIndices = _getAvailableIndices();
    final maxThumbnailsToShow = _maxVisibleThumbnails;
    final endIndex = (_thumbnailStartIndex + maxThumbnailsToShow)
        .clamp(0, availableIndices.length);
    return availableIndices.sublist(_thumbnailStartIndex, endIndex);
  }

  int get _remainingThumbnails {
    final availableIndices = _getAvailableIndices();
    final maxThumbnailsToShow = _maxVisibleThumbnails;
    final remaining =
        availableIndices.length - _thumbnailStartIndex - maxThumbnailsToShow;
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

  List<BetterPlayerController> get _allControllers {
    return _controllers
        .where((controller) => controller != null && controller.isReady)
        .map((controller) => controller!.controller)
        .toList();
  }

  Duration get _globalMaxDuration {
    // Return the maximum duration found across all videos (even disposed ones)
    if (_videoDurations.isNotEmpty) {
      return _videoDurations.values.reduce((a, b) => a > b ? a : b);
    }
    return _maxKnownDuration;
  }

  void _toggleDock() {
    setState(() {
      _showDock = !_showDock;
    });
  }

  void _ensureControllerLoaded(int index) {
    if (_controllers[index] == null) {
      _createOptimizedController(index);
      // Sync new controller to current time after a brief delay
      Timer(const Duration(milliseconds: 500), () {
        _syncControllerToCurrentTime(index);
      });
    }
  }

  void _loadVisibleThumbnailControllers() {
    final visibleIndices = _visibleThumbnailIndices;
    for (final index in visibleIndices) {
      final wasNew = _controllers[index] == null;
      _ensureControllerLoaded(index);

      // If this was a new controller, sync it after a delay
      if (wasNew) {
        Timer(const Duration(milliseconds: 800), () {
          _syncControllerToCurrentTime(index);
        });
      }
    }
  }

  void _updateCurrentSyncTime() {
    // Get current time from main video controller
    final mainController = _controllers[_mainVideoIndex];
    if (mainController != null && mainController.isReady) {
      try {
        final videoController = mainController.controller.videoPlayerController;
        if (videoController != null) {
          _currentSyncTime = videoController.value.position;
        }
      } catch (e) {
        debugPrint('Error getting current sync time: $e');
      }
    }
  }

  Future<void> _syncControllerToCurrentTime(int index) async {
    final controller = _controllers[index];
    if (controller == null) return;

    // Wait for controller to be ready with retries
    for (int attempt = 0; attempt < 10; attempt++) {
      if (controller.isReady) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!controller.isReady) {
      debugPrint('Controller $index not ready for sync after 1s');
      return;
    }

    _updateCurrentSyncTime();

    if (_currentSyncTime > Duration.zero) {
      try {
        await controller.controller.seekTo(_currentSyncTime);
        debugPrint(
            '✅ Synced controller $index to ${_currentSyncTime.inSeconds}s');
      } catch (e) {
        debugPrint('❌ Error syncing controller $index: $e');
      }
    }
  }

  Future<void> _syncAllVisibleControllers() async {
    _updateCurrentSyncTime();

    if (_currentSyncTime <= Duration.zero) return;

    final futures = <Future>[];

    // Sync visible thumbnail controllers
    for (final index in _visibleThumbnailIndices) {
      if (_controllers[index] != null && _controllers[index]!.isReady) {
        futures.add(_syncControllerToCurrentTime(index));
      }
    }

    await Future.wait(futures);
  }

  void _manageControllerPool() {
    final activeControllers = <int>[];

    // Always keep main video
    activeControllers.add(_mainVideoIndex);

    // Add visible thumbnails
    activeControllers.addAll(_visibleThumbnailIndices);

    // Count current loaded controllers
    final loadedControllers = <int>[];
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i] != null) {
        loadedControllers.add(i);
      }
    }

    // Ultra-conservative limit - only absolutely essential controllers
    const strictLimit =
        2; // Only main video + 1 thumbnail max to prevent memory issues

    // If we have too many controllers, dispose the ones not visible
    if (loadedControllers.length > strictLimit) {
      final controllersToDispose = loadedControllers
          .where((index) => !activeControllers.contains(index))
          .toList();

      // Sort by priority (further from main video and visible thumbnails)
      controllersToDispose.sort((a, b) {
        final aDistance = (a - _mainVideoIndex).abs();
        final bDistance = (b - _mainVideoIndex).abs();
        return bDistance.compareTo(aDistance); // Dispose furthest first
      });

      // Dispose controllers aggressively to maintain performance
      final excessCount = loadedControllers.length - strictLimit;

      for (int i = 0; i < excessCount && i < controllersToDispose.length; i++) {
        final index = controllersToDispose[i];

        try {
          _controllers[index]?.dispose();
          _controllers[index] = null;
        } catch (e) {
          debugPrint('❌ Error disposing controller $index: $e');
          _controllers[index] = null;
        }
      }
    } else {
      debugPrint(
          '✅ Pool management: ${loadedControllers.length} controllers loaded (within limit of $strictLimit)');
    }
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
                    if (_showDock) ...[
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const ButtonGoBack(),
                            Container(
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
                            ButtonDownload(
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    // Main video area
                    Expanded(
                      flex: _showDock ? 3 : 4,
                      child: ClipRRect(
                        child: GestureDetector(
                          onTap: _toggleDock,
                          child: _buildOptimizedVideo(_mainVideoIndex,
                              isMain: true),
                        ),
                      ),
                    ),
                    // Dock
                    if (_showDock) ...[
                      Expanded(
                        flex: 1,
                        child: SyncDock(
                          key: ValueKey('sync_dock_${_allControllers.length}'),
                          mainController:
                              _controllers[_mainVideoIndex]?.isReady == true
                                  ? _controllers[_mainVideoIndex]!.controller
                                  : null,
                          allControllers: _allControllers,
                          globalMaxDuration: _globalMaxDuration,
                        ),
                      ),
                    ]
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
                  child: Column(children: [
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
                              child: _buildOptimizedVideo(originalIndex),
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
                  ]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
