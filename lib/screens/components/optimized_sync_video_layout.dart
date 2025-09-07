import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'sync_dock.dart';

class OptimizedSyncVideoLayout extends StatefulWidget {
  final List<String> videoUrls;

  const OptimizedSyncVideoLayout({super.key, required this.videoUrls});

  @override
  State<OptimizedSyncVideoLayout> createState() => _OptimizedSyncVideoLayoutState();
}

class _OptimizedSyncVideoLayoutState extends State<OptimizedSyncVideoLayout> {
  int _mainVideoIndex = 0;
  bool _showDock = false;
  final List<BetterPlayerController?> _controllers = [];
  bool _allControllersReady = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.videoUrls.length; i++) {
      _controllers.add(null);
    }
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    for (int i = 0; i < widget.videoUrls.length; i++) {
      if (_controllers[i] == null) {
        await _createOptimizedController(i);
      }
    }
    _checkIfAllControllersReady();
  }

  void _checkIfAllControllersReady() {
    final allReady = _controllers.every((controller) => controller != null);
    if (allReady && !_allControllersReady) {
      setState(() {
        _allControllersReady = true;
      });
      _synchronizeAllVideosStart();
    }
  }

  Future<void> _synchronizeAllVideosStart() async {
    debugPrint('Preparing synchronized videos - seeking to start position');
    
    // Only seek all videos to position 0, don't auto-start
    for (final controller in _controllers) {
      if (controller != null) {
        try {
          await controller.seekTo(Duration.zero);
        } catch (e) {
          debugPrint('Error seeking to start: $e');
        }
      }
    }
    
    debugPrint('All videos prepared at position 0 - ready for dock control');
  }

  Future<void> _createOptimizedController(int index) async {
    try {
      final config = const BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        autoPlay: false, // Don't auto play - we'll start them synchronously
        startAt: Duration.zero, // Start at beginning
        handleLifecycle: false,
        allowedScreenSleep: true,
        // Disable unnecessary features to save memory
        autoDetectFullscreenDeviceOrientation: false,
        deviceOrientationsAfterFullScreen: [],
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false, // Always hide native controls - we use custom dock
          enableOverflowMenu: false,
          enablePlayPause: false, // Disable native controls
          enableMute: false,
          enableFullscreen: false,
          enablePip: false,
          enablePlaybackSpeed: false,
          enableProgressText: false,
          enableProgressBar: false,
          enableSkips: false,
          enableAudioTracks: false,
          enableSubtitles: false,
          enableQualities: false,
        ),
      );

      // Optimized data source with minimal buffering
      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.videoUrls[index],
        liveStream: false,
        videoFormat: BetterPlayerVideoFormat.other,
        // Aggressive memory optimization
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 500,   // Minimal buffer
          maxBufferMs: 2000,  // Very small max buffer
          bufferForPlaybackMs: 200,
          bufferForPlaybackAfterRebufferMs: 500,
        ),
        // Request lower resolution
        headers: {
          'Accept': 'video/mp4;q=0.5, video/webm;q=0.3, video/*;q=0.1',
          'User-Agent': 'Flutter-OptimizedPlayer/1.0',
          'Range': 'bytes=0-', // Enable range requests for better streaming
        },
      );

      final controller = BetterPlayerController(config, betterPlayerDataSource: dataSource);
      
      if (mounted) {
        setState(() {
          _controllers[index] = controller;
        });
        _checkIfAllControllersReady();
      }

      debugPrint('Optimized controller created for video $index');
    } catch (e) {
      debugPrint('Error creating optimized controller for video $index: $e');
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
    debugPrint('Toggle dock: ${!_showDock}, controllers: ${_allControllers.length}');
    setState(() {
      _showDock = !_showDock;
    });
  }

  List<int> get _visibleThumbnailIndices {
    List<int> indices = List.generate(widget.videoUrls.length, (index) => index);
    indices.removeAt(_mainVideoIndex);
    return indices.take(2).toList();
  }

  List<BetterPlayerController> get _allControllers {
    return _controllers.where((c) => c != null).cast<BetterPlayerController>().toList();
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
    
    if (controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return BetterPlayer(controller: controller);
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
                                child: _buildOptimizedVideo(_mainVideoIndex, isMain: true),
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
                            key: ValueKey('sync_dock_${_allControllers.length}'),
                            mainController: _controllers[_mainVideoIndex],
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
                                border: Border.all(color: Colors.grey, width: 2),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(3),
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