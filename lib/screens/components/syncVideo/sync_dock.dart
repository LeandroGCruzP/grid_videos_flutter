import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class SyncDock extends StatefulWidget {
  final BetterPlayerController? mainController;
  final List<BetterPlayerController> allControllers;
  final Duration? globalMaxDuration;

  const SyncDock({
    super.key,
    this.mainController,
    required this.allControllers,
    this.globalMaxDuration,
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
    
    // Use global max duration if provided, otherwise find among active controllers
    Duration maxDuration = widget.globalMaxDuration ?? Duration.zero;
    Duration maxCurrentPos = Duration.zero;
    bool anyPlaying = false;
    bool anyStillHasTime = false; // Track if any video still has time left
    
    for (final controller in widget.allControllers) {
      final videoController = controller.videoPlayerController;
      if (videoController != null) {
        final duration = videoController.value.duration ?? Duration.zero;
        final position = videoController.value.position;
        
        // Only update max duration if we don't have a global one
        if (widget.globalMaxDuration == null && duration > maxDuration) {
          maxDuration = duration;
        }
        
        // Use the furthest position among all videos (the one that's progressed most)
        if (position > maxCurrentPos) {
          maxCurrentPos = position;
        }
        
        // Check if this video is playing OR should continue playing (hasn't reached global max)
        final videoHasEnded = duration.inMilliseconds > 0 && 
            position.inMilliseconds >= duration.inMilliseconds - 500;
        
        if (videoController.value.isPlaying && !videoHasEnded) {
          anyPlaying = true;
        }
        
        // Check if any video still has time relative to global duration
        if (position.inMilliseconds < maxDuration.inMilliseconds - 1000) {
          anyStillHasTime = true;
        }
      }
    }
    
    // If we have global duration and videos still have time, consider as playing
    // even if some individual videos have ended
    final shouldShowAsPlaying = anyPlaying || (anyStillHasTime && _isPlaying);
    
    setState(() {
      _isPlaying = shouldShowAsPlaying;
      _currentPosition = maxCurrentPos;
      _totalDuration = maxDuration;
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
    
    // Check current state of all videos and if they've ended
    final playingVideos = <int>[];
    final pausedVideos = <int>[];
    final endedVideos = <int>[];
    final globalMaxDuration = widget.globalMaxDuration ?? Duration.zero;
    
    for (int i = 0; i < widget.allControllers.length; i++) {
      final controller = widget.allControllers[i];
      final videoController = controller.videoPlayerController;
      if (videoController != null) {
        final isCurrentlyPlaying = videoController.value.isPlaying;
        final position = videoController.value.position;
        final duration = videoController.value.duration ?? Duration.zero;
        
        // Check if video has ended relative to its OWN duration
        final hasEndedIndividually = duration.inMilliseconds > 0 && 
            (position.inMilliseconds >= duration.inMilliseconds - 1000);
            
        // Check if we've reached the global max duration (all should stop)
        final hasReachedGlobalEnd = globalMaxDuration.inMilliseconds > 0 &&
            (position.inMilliseconds >= globalMaxDuration.inMilliseconds - 1000);
        
        if (hasReachedGlobalEnd) {
          endedVideos.add(i);
        } else if (isCurrentlyPlaying && !hasEndedIndividually) {
          playingVideos.add(i);
        } else {
          pausedVideos.add(i);
        }
      }
    }
    
    debugPrint('SyncDock: State - Playing: $playingVideos, Paused: $pausedVideos, Ended: $endedVideos (Global duration: ${globalMaxDuration.inSeconds}s)');
    
    // Only restart if we've reached the GLOBAL max duration
    final currentMaxPosition = _getCurrentMaxPosition();
    final shouldRestart = globalMaxDuration.inMilliseconds > 0 && 
        currentMaxPosition.inMilliseconds >= globalMaxDuration.inMilliseconds - 1000;
        
    if (shouldRestart) {
      debugPrint('SyncDock: Reached global max duration, restarting from beginning');
      await _seekAll(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Decide action based on current state
    final shouldPause = playingVideos.isNotEmpty;
    
    debugPrint('SyncDock: Action - ${shouldPause ? "Pausing" : "Playing"} all ${widget.allControllers.length} videos');
    
    // Apply action to all videos simultaneously, but handle ended videos specially
    final futures = widget.allControllers.asMap().entries.map((entry) async {
      final index = entry.key;
      final controller = entry.value;
      final videoController = controller.videoPlayerController;
      
      if (videoController != null) {
        final position = videoController.value.position;
        final duration = videoController.value.duration ?? Duration.zero;
        final hasEndedIndividually = duration.inMilliseconds > 0 && 
            (position.inMilliseconds >= duration.inMilliseconds - 500);
        
        try {
          if (shouldPause) {
            await controller.pause();
            debugPrint('SyncDock: Video $index paused');
          } else {
            // If video has ended individually but we're still within global time,
            // don't try to play it (it will stay at last frame)
            if (!hasEndedIndividually) {
              await controller.play();
              debugPrint('SyncDock: Video $index started');
            } else {
              debugPrint('SyncDock: Video $index ended individually, staying at last frame');
            }
          }
        } catch (e) {
          debugPrint('SyncDock: Error controlling video $index: $e');
        }
      }
    });
    
    await Future.wait(futures);
    debugPrint('SyncDock: All videos synchronized - ${shouldPause ? "paused" : "playing"}');
  }
  
  Duration _getCurrentMaxPosition() {
    Duration maxPos = Duration.zero;
    for (final controller in widget.allControllers) {
      final videoController = controller.videoPlayerController;
      if (videoController != null) {
        final position = videoController.value.position;
        if (position > maxPos) {
          maxPos = position;
        }
      }
    }
    return maxPos;
  }

  Future<void> _seekAll(Duration position) async {
    debugPrint('SyncDock: Seeking all videos to ${position.inSeconds}s');
    
    // Seek all videos simultaneously, but respect individual video durations
    final futures = widget.allControllers.asMap().entries.map((entry) async {
      final index = entry.key;
      final controller = entry.value;
      final videoController = controller.videoPlayerController;
      
      if (videoController != null) {
        final videoDuration = videoController.value.duration ?? Duration.zero;
        
        try {
          // Don't seek beyond individual video duration
          if (videoDuration.inMilliseconds > 0 && 
              position.inMilliseconds > videoDuration.inMilliseconds) {
            // Seek to the end of this specific video
            await controller.seekTo(videoDuration);
            debugPrint('SyncDock: Video $index seeked to its end (${videoDuration.inSeconds}s)');
          } else {
            await controller.seekTo(position);
            debugPrint('SyncDock: Video $index seeked to ${position.inSeconds}s');
          }
        } catch (e) {
          debugPrint('Error seeking video $index: $e');
        }
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
                
                // Progress slider
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color.fromARGB(255, 246, 221, 140),
                      inactiveTrackColor: Colors.white.withOpacity(0.9),
                      thumbColor: const Color(0xFFFFC501),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _totalDuration.inMilliseconds > 0
                          ? (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0)
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
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Play/Pause
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _playPauseAll,
                    alignment: Alignment.center,
                    iconSize: 16,
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: const Color(0xFF484847),
                      size: 16,
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
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                    size: 32,
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