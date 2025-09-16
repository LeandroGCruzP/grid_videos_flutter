import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:multi_video/screens/components/channel_name.dart';
import 'package:multi_video/screens/components/loading_video.dart';
import 'package:multi_video/screens/controllers/sync_video_better_player_controller.dart';

class SyncVideoCard extends StatelessWidget {
  final int channel;
  final SyncVideoBetterPlayerController syncVideoBetterPlayerController;
  final VoidCallback onTap;

  const SyncVideoCard({super.key, required this.syncVideoBetterPlayerController, required this.onTap, required this.channel});

  @override
  Widget build(BuildContext context) {
    final isReady = syncVideoBetterPlayerController.isReady;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Channel name
          ChannelName(channelNumber: channel),
          // Video Player
          Flexible(
            child: Center(
              child: GestureDetector(
                onTap: onTap, 
                child: !isReady
                  ? const LoadingVideo()
                  : BetterPlayer(controller: syncVideoBetterPlayerController.controller),
              )
            ),
          ),
        ],
      )
    );
  }
}
