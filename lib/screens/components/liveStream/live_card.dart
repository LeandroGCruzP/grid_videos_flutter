import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:multi_video/screens/components/channel_name.dart';
import 'package:multi_video/screens/components/loading_video.dart';
import 'package:multi_video/screens/controllers/live_stream_better_player_controller.dart';

class LiveCard extends StatelessWidget {
  final int channel;
  final LiveStreamBetterPlayerController liveStreamBetterPlayerController;

  const LiveCard({super.key, required this.liveStreamBetterPlayerController, required this.channel});

  @override
  Widget build(BuildContext context) {
    final isReady = liveStreamBetterPlayerController.isReady;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Channel name
          ChannelName(channel: channel),
          // Video Player
          Flexible(
            child: Center(
              child: !isReady
                ? const LoadingVideo()
                : BetterPlayer(controller: liveStreamBetterPlayerController.controller)
            ),
          ),
        ],
      )
    );
  }
}
