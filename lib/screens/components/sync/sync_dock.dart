import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:multi_video/screens/components/sync/button_change_sync_channels.dart';
import 'package:multi_video/screens/controllers/sync_bp_controller.dart';
import 'package:multi_video/screens/controllers/sync_controller.dart';

class SyncDock extends StatefulWidget {
  final Map<int, SyncBPController> syncBPControllers;
  final SyncController syncController;

  const SyncDock({super.key, required this.syncBPControllers, required this.syncController});

  @override
  State<SyncDock> createState() => _SyncDockState();
}

class _SyncDockState extends State<SyncDock> {
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  BetterPlayerController? _masterController;
  bool _isPlaying = false;

  void _controllerMaster() {
    if (widget.syncBPControllers.isNotEmpty) {
      try {
        SyncBPController? masterCandidate;
        Duration maxDuration = Duration.zero;

        for (var syncBPController in widget.syncBPControllers.values) {
          if (syncBPController.isReady) {
            final controllerDuration =
                syncBPController.controller.videoPlayerController?.value.duration ??
                    Duration.zero;
            if (controllerDuration > maxDuration) {
              maxDuration = controllerDuration;
              masterCandidate = syncBPController;
            }
          }
        }

        if (masterCandidate != null) {
          _masterController = masterCandidate.controller;
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
        });

        final newDuration = event.parameters?["duration"] ?? Duration.zero;
        if (newDuration != _total) {
          setState(() {
            _total = newDuration;
          });
        }

        final isPlaying = _masterController?.isPlaying() ?? false;
        if (isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }

        break;

      case BetterPlayerEventType.play:
        setState(() {
          _isPlaying = true;
        });
        break;

      case BetterPlayerEventType.pause:
      case BetterPlayerEventType.finished:
        setState(() {
          _isPlaying = false;
        });
        break;

      default:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    // Delay to set up master controller after all videos are likely initialized
    Future.delayed(const Duration(seconds: 2), () {
      _controllerMaster();
    });
  }

  void _seekAll(Duration position) async {
    for (var syncBPController in widget.syncBPControllers.values) {
      try {
        if (syncBPController.isReady) {
          await syncBPController.controller.seekTo(position);
          syncBPController.controller.play();
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
      for (var syncBPController in widget.syncBPControllers.values) {
        try {
          if (syncBPController.isReady) {
            syncBPController.controller.pause();
          }
        } catch (e) {
          debugPrint('❌ Error pausing controller: $e');
        }
      }
    } else {
      for (var syncBPController in widget.syncBPControllers.values) {
        try {
          if (syncBPController.isReady) {
            syncBPController.controller.play();
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
    // Don't dispose controllers here - they're managed by SyncVideoPage
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
                  value: _total.inSeconds > 0
                      ? _position.inSeconds
                          .toDouble()
                          .clamp(0.0, _total.inSeconds.toDouble())
                      : 0.0,
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
        SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              // Play/Pause and Seek buttons centered
              Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () =>
                          _changeTimePosition(_position.inSeconds - 10),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.replay_10,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color.fromARGB(31, 88, 88, 88),
                            width: 1),
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
                    IconButton(
                      onPressed: () =>
                          _changeTimePosition(_position.inSeconds + 10),
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

              // Swap Channels button aligned to the right
              Align(
                alignment: Alignment.centerRight,
                child: ListenableBuilder(
                  listenable: widget.syncController,
                  builder: (context, child) => ButtonChangeSyncChannels(
                    syncController: widget.syncController,
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
