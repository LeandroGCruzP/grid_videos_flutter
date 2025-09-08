import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
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
      });
    }
  }

  void _toggleDock() {
    setState(() {
      _showDock = !_showDock;
    });
  }

  List<int> get _visibleThumbnailIndices {
    List<int> indices =
        List.generate(widget.videoUrls.length, (index) => index);
    indices.removeAt(_mainVideoIndex);
    return indices.take(2).toList(); // Show only first 2 thumbnails
  }

  List<BetterPlayerController> get _allControllers {
    return _controllers
        .where((controller) => controller != null && controller.isReady)
        .map((controller) => controller!.controller)
        .toList();
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
                          border: Border.all(color: Colors.grey, width: 2),
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
                            border: Border.all(color: Colors.grey, width: 1),
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

            // Optimized thumbnails
            if (widget.videoUrls.length > 1)
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.only(right: 4, top: 4, bottom: 4),
                  child: Column(
                    children: _visibleThumbnailIndices.map((originalIndex) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onTap: () => _setMainVideo(originalIndex),
                            child: Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey, width: 2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Stack(
                                  children: [
                                    _buildOptimizedVideo(originalIndex),
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          '${originalIndex + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
