import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multi_video/screens/components/header.dart';
import 'package:multi_video/screens/components/syncVideo/sync_dock.dart';
import 'package:multi_video/screens/components/syncVideo/sync_video_card.dart';
import 'package:multi_video/screens/controllers/sync_video_better_player_controller.dart';

class SyncVideoLayout extends StatefulWidget {
  final List<Map<String, dynamic>> videos;

  const SyncVideoLayout({super.key, required this.videos});

  @override
  State<SyncVideoLayout> createState() => _SyncVideoLayoutState();
}

class _SyncVideoLayoutState extends State<SyncVideoLayout> {
  final Map<int, SyncVideoBetterPlayerController> _controllers = {};
  // final Map<int, Duration> _videoDurations = {}; // Cache video durations

  static const int totalVideos = 3;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    for (int i = 0; i < widget.videos.length && i < totalVideos; i++) {
      final video = widget.videos[i];
      final channel = video["channel"] as int;
      _controllers[channel] = SyncVideoBetterPlayerController(video["url"]);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return const Center(child: Text('No videos available'));
    }

    return Stack(
      children: [
        // Video area
        Row(
          children: List.generate(
            totalVideos,
            (index) {
              if (index >= widget.videos.length) {
                return const SizedBox.shrink();
              }
        
              final video = widget.videos[index];
              final channel = video["channel"] as int;
              final controller = _controllers[channel];
        
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < totalVideos - 1 ? 4.0 : 0),
                  child: controller != null 
                    ? SyncVideoCard(
                        controller: controller,
                        chanel: channel,
                        onTap: () {},
                      )
                    : const SizedBox.shrink(),
                )
              );
            },
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Header(),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SyncDock(
            controllers: _controllers,
          ),
        ),
      ],
    );
  }
}
