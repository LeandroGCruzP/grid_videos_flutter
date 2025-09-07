import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SyncDock extends StatefulWidget {
  final BetterPlayerController? mainController;
  final List<BetterPlayerController> allControllers;

  const SyncDock({
    super.key,
    this.mainController,
    required this.allControllers,
  });

  @override
  State<SyncDock> createState() => _SyncDockState();
}

class _SyncDockState extends State<SyncDock> {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription? _positionSubscription;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('SyncDock: Initializing with ${widget.allControllers.length} controllers');
    _setupListeners();
    _startPositionUpdates();
  }

  @override
  void didUpdateWidget(SyncDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allControllers != widget.allControllers) {
      debugPrint('SyncDock: Controllers updated from ${oldWidget.allControllers.length} to ${widget.allControllers.length}');
      _setupListeners();
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    // Listen to all controllers, not just main
    for (final controller in widget.allControllers) {
      if (controller.videoPlayerController != null) {
        controller.videoPlayerController!.addListener(_updateState);
      }
    }
    _updateState();
  }

  void _updateState() {
    if (!mounted || widget.allControllers.isEmpty) return;
    
    // Use the first available controller for state reference
    final controller = widget.allControllers.first.videoPlayerController;
    if (controller == null) return;
    
    setState(() {
      _isPlaying = controller.value.isPlaying;
      _currentPosition = controller.value.position;
      _totalDuration = controller.value.duration ?? Duration.zero;
    });
  }

  void _startPositionUpdates() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && _isPlaying) {
        _updateState();
      }
    });
  }

  Future<void> _playPauseAll() async {
    if (widget.allControllers.isEmpty) {
      debugPrint('SyncDock: No controllers available!');
      return;
    }
    
    // Check current state of all videos
    final playingVideos = <int>[];
    final pausedVideos = <int>[];
    
    for (int i = 0; i < widget.allControllers.length; i++) {
      final controller = widget.allControllers[i];
      final isCurrentlyPlaying = controller.videoPlayerController?.value.isPlaying ?? false;
      if (isCurrentlyPlaying) {
        playingVideos.add(i);
      } else {
        pausedVideos.add(i);
      }
    }
    
    debugPrint('SyncDock: Current state - Playing: $playingVideos, Paused: $pausedVideos');
    
    // Decide action based on majority or if any is playing, pause all, otherwise play all
    final shouldPause = playingVideos.isNotEmpty;
    
    debugPrint('SyncDock: Action - ${shouldPause ? "Pausing" : "Playing"} all ${widget.allControllers.length} videos');
    
    // Apply action to all videos simultaneously
    final futures = widget.allControllers.asMap().entries.map((entry) async {
      final index = entry.key;
      final controller = entry.value;
      try {
        if (shouldPause) {
          await controller.pause();
          debugPrint('SyncDock: Video $index paused');
        } else {
          await controller.play();
          debugPrint('SyncDock: Video $index started');
        }
      } catch (e) {
        debugPrint('SyncDock: Error controlling video $index: $e');
      }
    });
    
    await Future.wait(futures);
    debugPrint('SyncDock: All videos synchronized - ${shouldPause ? "paused" : "playing"}');
  }

  Future<void> _seekAll(Duration position) async {
    debugPrint('SyncDock: Seeking all videos to ${position.inSeconds}s');
    
    // Seek all videos simultaneously for perfect sync
    final futures = widget.allControllers.map((controller) async {
      try {
        await controller.seekTo(position);
      } catch (e) {
        debugPrint('Error seeking video: $e');
      }
    });
    
    await Future.wait(futures);
    debugPrint('SyncDock: All videos synchronized at ${position.inSeconds}s');
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Progress bar
          Expanded(
            child: Row(
              children: [
                // Time current
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Progress slider
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _totalDuration.inMilliseconds > 0
                          ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                          : 0.0,
                      onChanged: (value) {
                        final position = Duration(
                          milliseconds: (value * _totalDuration.inMilliseconds).round(),
                        );
                        _seekAll(position);
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                // Time total
                Text(
                  _formatDuration(_totalDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Controls row
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Skip back 10s
                IconButton(
                  onPressed: () {
                    final newPosition = _currentPosition - const Duration(seconds: 10);
                    _seekAll(newPosition.isNegative ? Duration.zero : newPosition);
                  },
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Play/Pause
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _playPauseAll,
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Skip forward 10s
                IconButton(
                  onPressed: () {
                    final newPosition = _currentPosition + const Duration(seconds: 10);
                    _seekAll(newPosition > _totalDuration ? _totalDuration : newPosition);
                  },
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}