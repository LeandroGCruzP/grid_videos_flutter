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
        final hasSelectedChannels = widget.syncController.selectedChannels.isNotEmpty;

        return Column(
          children: [
            Row(
              children: [
                // Time current
                Text(
                  position.toString().split('.').first.padLeft(8, "0"),
                  style: TextStyle(
                    color: hasSelectedChannels ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                // Slider
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: hasSelectedChannels
                          ? const Color.fromARGB(255, 246, 221, 140)
                          : Colors.white.withValues(alpha: 0.3),
                      inactiveTrackColor: Colors.white.withValues(alpha: hasSelectedChannels ? 0.9 : 0.3),
                      thumbColor: hasSelectedChannels
                          ? const Color(0xFFFFC501)
                          : Colors.white.withValues(alpha: 0.5),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      value: total.inSeconds > 0
                          ? position.inSeconds
                              .toDouble()
                              .clamp(0.0, total.inSeconds.toDouble())
                          : 0.0,
                      max: total.inSeconds > 0 ? total.inSeconds.toDouble() : 1,
                      onChanged: hasSelectedChannels ? (value) => _changeTimePosition(value.toInt()) : null,
                    ),
                  ),
                ),
                // Time total
                Text(
                  total.toString().split('.').first.padLeft(8, "0"),
                  style: TextStyle(
                    color: hasSelectedChannels ? Colors.white : Colors.white.withValues(alpha: 0.5),
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
                          onPressed: hasSelectedChannels ? () =>
                              _changeTimePosition(position.inSeconds - 10) : null,
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.replay_10,
                            color: hasSelectedChannels ? Colors.white : Colors.white.withValues(alpha: 0.3),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 33,
                          height: 33,
                          decoration: BoxDecoration(
                            color: hasSelectedChannels ? Colors.white : Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color.fromARGB(31, 88, 88, 88),
                                width: 1),
                          ),
                          child: IconButton(
                            onPressed: hasSelectedChannels ? _togglePlay : null,
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: hasSelectedChannels ? const Color(0xFF343432) : const Color(0xFF343432).withValues(alpha: 0.3),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: hasSelectedChannels ? () =>
                              _changeTimePosition(position.inSeconds + 10) : null,
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.forward_10,
                            color: hasSelectedChannels ? Colors.white : Colors.white.withValues(alpha: 0.3),
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
