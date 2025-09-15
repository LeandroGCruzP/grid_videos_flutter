import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:multi_video/screens/controllers/sync_video_better_player_controller.dart';

class SyncDock extends StatefulWidget {
  final Map<int, SyncVideoBetterPlayerController> controllers;

  const SyncDock({super.key, required this.controllers});

  @override
  State<SyncDock> createState() => _SyncDockState();
}

class _SyncDockState extends State<SyncDock> {
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  BetterPlayerController? _masterController;
  bool _isPlaying = false;

  void _controllerMaster() {
    if (widget.controllers.isNotEmpty) {
      try {
        final firstController = widget.controllers.values.first;
        if (firstController.isReady) {
          _masterController = firstController.controller;
          _masterController?.addEventsListener(_onPlayerEvent);
        }
      } catch (e) {
        debugPrint('❌ Error setting up master controller: $e');
      }
    }
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (!mounted) return;

    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.progress:
        setState(() {
          _position = event.parameters?["progress"] ?? Duration.zero;
          _total = event.parameters?["duration"] ?? Duration.zero;
        });
        break;
      
      case BetterPlayerEventType.play:
        setState(() {
          _isPlaying = true;
        });
        break;
      
      case BetterPlayerEventType.pause:
        setState(() {
          _isPlaying = false;
        });
        break;
      
      case BetterPlayerEventType.initialized:
        // Check initial play state after initialization
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _masterController != null) {
            final isPlaying = _masterController!.isPlaying() ?? false;
            setState(() {
              _isPlaying = isPlaying;
            });
            debugPrint('📱 Initial play state after init: $isPlaying');
          }
        });
        break;
      
      default:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _controllerMaster();
  }

  void _seekAll(Duration position) async {
    for (var controller in widget.controllers.values) {
      try {
        if (controller.isReady) {
          await controller.controller.seekTo(position);
          controller.controller.play();
        }
      } catch (e) {
        debugPrint('❌ Error seeking controller: $e');
      }
    }
  }

  void _changeTimePosition(int value) {
    final newPosition = Duration(seconds: value.toInt());
    _seekAll(newPosition);
  }

  void _togglePlay() {
    if (_isPlaying) {
      for (var controller in widget.controllers.values) {
        try {
          if (controller.isReady) {
            controller.controller.pause();
          }
        } catch (e) {
          debugPrint('❌ Error pausing controller: $e');
        }
      }
    } else {
      for (var controller in widget.controllers.values) {
        try {
          if (controller.isReady) {
            controller.controller.play();
          }
        } catch (e) {
          debugPrint('❌ Error playing controller: $e');
        }
      }
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  void dispose() {
    _masterController?.removeEventsListener(_onPlayerEvent);
    // Don't dispose controllers here - they're managed by SyncVideoLayout
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Time current
            Text(
              _position.toString().split('.').first.padLeft(8, "0"),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            // Slider
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color.fromARGB(255, 246, 221, 140),
                  inactiveTrackColor: Colors.white.withOpacity(0.9),
                  thumbColor: const Color(0xFFFFC501),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _position.inSeconds.toDouble(),
                  max: _total.inSeconds > 0 ? _total.inSeconds.toDouble() : 1,
                  onChanged: (value) => _changeTimePosition(value.toInt()),
                ),
              ),
            ),
            // Time total
            Text(
              _total.toString().split('.').first.padLeft(8, "0"),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),

        // Controls row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Skip back 10s
            IconButton(
              onPressed: () => _changeTimePosition(_position.inSeconds - 10),
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
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color.fromARGB(31, 88, 88, 88), width: 1),
              ),
              child: IconButton(
                onPressed: _togglePlay,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: const Color(0xFF343432),
                  size: 16,
                ),
              ),
            ),
        
            const SizedBox(width: 16),
        
            // Skip forward 10s
            IconButton(
              onPressed: () => _changeTimePosition(_position.inSeconds + 10),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.forward_10,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
