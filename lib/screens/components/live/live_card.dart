import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:multi_video/screens/components/channel_name.dart';
import 'package:multi_video/screens/components/loading_video.dart';
import 'package:multi_video/screens/controllers/live_bp_controller.dart';

class LiveCard extends StatelessWidget {
  final int channel;
  final LiveBPController liveBPController;
  final VoidCallback? onTap;

  const LiveCard({super.key, required this.liveBPController, required this.channel, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isReady = liveBPController.isReady;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Channel name
          ChannelName(channel: channel),
          const SizedBox(height: 4),
          // Video Player
          Flexible(
            child: Center(
              child: GestureDetector(
                onTap: onTap,
                child: !isReady
                  ? const LoadingVideo()
                  : BetterPlayer(controller: liveBPController.controller)
              ),
            ),
          ),
        ],
      )
    );
  }
}
