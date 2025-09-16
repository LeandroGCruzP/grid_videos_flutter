import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_video/screens/components/header.dart';
import 'package:multi_video/screens/components/syncVideo/sync_dock.dart';
import 'package:multi_video/screens/components/syncVideo/sync_video_card.dart';
import 'package:multi_video/screens/const/sync_const.dart';
import 'package:multi_video/screens/controllers/sync_video_better_player_controller.dart';
import 'package:multi_video/screens/controllers/sync_video_controller.dart';

class SyncVideoPage extends StatefulWidget {
  final List<Map<String, dynamic>> videos;

  const SyncVideoPage({super.key, required this.videos});

  @override
  State<SyncVideoPage> createState() => _SyncVideoPageState();
}

class _SyncVideoPageState extends State<SyncVideoPage> {
  late SyncVideoController _syncVideoController;
  final Map<int, SyncVideoBetterPlayerController> _syncVideoBetterPlayerControllers = {};

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _syncVideoController = SyncVideoController();

    _syncVideoController.addListener(() {
      debugPrint('🚀 Selected channels: ${_syncVideoController.selectedChannels}');
      debugPrint('🚀 All channels: ${_syncVideoController.allChannelsKeys}');
    });

    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    for (final video in widget.videos) {
      final channel = video["channel"];
      _syncVideoController.addChannel(channel);
    }

    for (int i = 0; i < widget.videos.length && i < maxChannelsToShow; i++) {
      final video = widget.videos[i];
      final channel = video["channel"];
      _syncVideoBetterPlayerControllers[channel] = SyncVideoBetterPlayerController(video["url"]); // aqui não converte para string
      _syncVideoController.toggleChannel(channel);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _syncVideoController.dispose();

    for (final syncVideoBetterPlayerController in _syncVideoBetterPlayerControllers.values) {
      syncVideoBetterPlayerController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return const Center(child: Text('No videos available'));
    }
    
    return AnimatedBuilder(
      animation: _syncVideoController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF484847),
          body: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Stack(
              children: [
                // Video area
                Row(
                  children: List.generate(
                    maxChannelsToShow,
                    (index) {
                      if (index >= widget.videos.length) {
                        return const SizedBox.shrink();
                      }
                
                      final video = widget.videos[index];
                      final channel = video["channel"];
                      final syncVideoBetterPlayerController = _syncVideoBetterPlayerControllers[channel];
                
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: index < maxChannelsToShow - 1 ? 4.0 : 0),
                          child: syncVideoBetterPlayerController != null 
                            ? SyncVideoCard(
                                syncVideoBetterPlayerController: syncVideoBetterPlayerController,
                                channel: channel,
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
                    syncVideoBetterPlayerControllers: _syncVideoBetterPlayerControllers,
                    syncController: _syncVideoController,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
