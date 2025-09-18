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

  void _changeTimePosition(int value) {
    final newPosition = Duration(seconds: value.toInt());
    widget.syncController.seekAll(newPosition);
  }

  void _togglePlay() {
    final isPlaying = widget.syncController.isPlaying;

    if (isPlaying) {
      widget.syncController.pauseAll();
    } else {
      widget.syncController.playAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.syncController,
      builder: (context, child) {
        final position = widget.syncController.currentPosition;
        final total = widget.syncController.totalDuration;
        final isPlaying = widget.syncController.isPlaying;

        return Column(
          children: [
            Row(
              children: [
                // Time current
                Text(
                  position.toString().split('.').first.padLeft(8, "0"),
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
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.9),
                      thumbColor: const Color(0xFFFFC501),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: total.inSeconds > 0
                          ? position.inSeconds
                              .toDouble()
                              .clamp(0.0, total.inSeconds.toDouble())
                          : 0.0,
                      max: total.inSeconds > 0 ? total.inSeconds.toDouble() : 1,
                      onChanged: (value) => _changeTimePosition(value.toInt()),
                    ),
                  ),
                ),
                // Time total
                Text(
                  total.toString().split('.').first.padLeft(8, "0"),
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
                              _changeTimePosition(position.inSeconds - 10),
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
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: const Color(0xFF343432),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () =>
                              _changeTimePosition(position.inSeconds + 10),
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
                    child: ButtonChangeSyncChannels(
                      syncController: widget.syncController,
                    ),
                  )
                ],
              ),
            )
          ],
        );
      },
    );
  }
}
