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

    // _syncVideoController.addListener(() {
    //   debugPrint('🚀 Selected channels: ${_syncVideoController.selectedChannels}');
    //   debugPrint('🚀 All channels: ${_syncVideoController.allChannelsKeys}');
    // });

    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    _syncVideoController.setControllerCallbacks(
      _createController,
      _disposeController,
    );

    for (final video in widget.videos) {
      final channel = video["channel"];
      final url = video["url"];
      _syncVideoController.addChannel(channel, url);
    }

    for (int i = 0; i < widget.videos.length && i < maxChannelsToShow; i++) {
      final video = widget.videos[i];
      final channel = video["channel"];
      _syncVideoController.toggleChannel(channel);
    }
  }

  SyncVideoBetterPlayerController _createController(int channel, String url) {
    // debugPrint('✅ Creating controller for channel $channel with URL: $url');
    final controller = SyncVideoBetterPlayerController(url);
    _syncVideoBetterPlayerControllers[channel] = controller;
    return controller;
  }

  void _disposeController(int channel) {
    final controller = _syncVideoBetterPlayerControllers.remove(channel);

    if (controller != null) {
      try {
        controller.dispose();
        debugPrint('✅ Channel $channel disposed successfully');
      } catch (e) {
        debugPrint('❌ Error disposing: $e');
      }
    }
  }

  @override
  void dispose() {
    debugPrint('🔄 Disposing SyncVideoPage...');

    // Step 1: Dispose all video controllers first to free resources
    final controllerKeys = _syncVideoBetterPlayerControllers.keys.toList();
    for (final channel in controllerKeys) {
      final controller = _syncVideoBetterPlayerControllers[channel];
      if (controller != null) {
        try {
          controller.dispose();
          debugPrint('✅ Video controller for channel $channel disposed');
        } catch (e) {
          debugPrint('❌ Error disposing video controller for channel $channel: $e');
        }
      }
    }
    _syncVideoBetterPlayerControllers.clear();

    // Step 2: Dispose sync controller
    try {
      _syncVideoController.dispose();
      debugPrint('✅ Sync controller disposed');
    } catch (e) {
      debugPrint('❌ Error disposing sync controller: $e');
    }

    // Step 3: Restore device orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    debugPrint('✅ SyncVideoPage disposed successfully');
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
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: _syncVideoController.selectedChannels.asMap().entries.map((entry) {
                          final index = entry.key;
                          final channel = entry.value;
                          final syncVideoBetterPlayerController = _syncVideoBetterPlayerControllers[channel];
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: index < _syncVideoController.selectedChannels.length - 1 ? 4.0 : 0),
                              child: syncVideoBetterPlayerController != null
                                  ? SyncVideoCard(
                                      key: ValueKey(channel),
                                      syncVideoBetterPlayerController: syncVideoBetterPlayerController,
                                      channel: channel,
                                      onTap: () {},
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }).toList(),
                      ),
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Header(),
                      ),
                    ],
                  ),
                ),
                SyncDock(
                  syncVideoBetterPlayerControllers: _syncVideoBetterPlayerControllers,
                  syncController: _syncVideoController,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}