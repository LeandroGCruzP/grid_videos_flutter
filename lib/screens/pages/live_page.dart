import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_video/screens/components/button_go_back.dart';
import 'package:multi_video/screens/components/live/button_change_live_channels.dart';
import 'package:multi_video/screens/components/live/live_card.dart';
import 'package:multi_video/screens/const/live_const.dart';
import 'package:multi_video/screens/controllers/live_bp_controller.dart';
import 'package:multi_video/screens/controllers/live_controller.dart';

class LivePage extends StatefulWidget {
  final List<Map<String, dynamic>> lives;

  const LivePage({super.key, required this.lives});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  late LiveController _liveController;
  final Map<int, LiveBPController> _liveBPControllers = {};

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _liveController = LiveController();

    // _liveController.addListener(() {
    //   debugPrint('🚀 Selected channels: ${_liveController.selectedChannels}');
    //   debugPrint('🚀 All channels: ${_liveController.allChannelsKeys}');
    // });

    _initializeControllers();
  }
  
  Future<void> _initializeControllers() async {
    _liveController.setControllerCallbacks(
      _createController,
      _disposeController,
    );

    for (final video in widget.lives) {
      final channel = video["channel"];
      final url = video["url"];
      _liveController.addChannel(channel, url);
    }

    for (int i = 0; i < widget.lives.length && i < maxLiveChannelsToShow; i++) {
      final video = widget.lives[i];
      final channel = video["channel"];
      _liveController.toggleChannel(channel);
    }
  }

  LiveBPController _createController(int channel, String url) {
    // debugPrint('✅ Creating controller for channel $channel with URL: $url');
    final controller = LiveBPController(url);
    _liveBPControllers[channel] = controller;
    return controller;
  }

  void _disposeController(int channel) {
    final controller = _liveBPControllers.remove(channel);

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
    debugPrint('🔄 Disposing LivePage...');

    // Step 1: Dispose all video controllers first to free resources
    final controllerKeys = _liveBPControllers.keys.toList();
    for (final channel in controllerKeys) {
      final controller = _liveBPControllers[channel];
      if (controller != null) {
        try {
          controller.dispose();
          debugPrint('✅ Video controller for channel $channel disposed');
        } catch (e) {
          debugPrint('❌ Error disposing video controller for channel $channel: $e');
        }
      }
    }
    _liveBPControllers.clear();

    // Step 2: Dispose live stream controller
    try {
      _liveController.dispose();
      debugPrint('✅ Live stream controller disposed');
    } catch (e) {
      debugPrint('❌ Error disposing live stream controller: $e');
    }

    // Step 3: Restore device orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    debugPrint('✅ LivePage disposed successfully');
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (widget.lives.isEmpty) {
      return const Center(child: Text('No videos available'));
    }

    return AnimatedBuilder(
      animation: _liveController,
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
                        children: _liveController.selectedChannels.asMap().entries.map((entry) {
                          final index = entry.key;
                          final channel = entry.value;
                          final liveStreamBetterPlayerController = _liveBPControllers[channel];
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: index < _liveController.selectedChannels.length - 1 ? 4.0 : 0),
                              child: liveStreamBetterPlayerController != null
                                  ? LiveCard(
                                      key: ValueKey(channel),
                                      channel: channel,
                                      // videoUrl: _liveController.getChannelUrl(channel) ?? '',
                                      // onTap: () {},
                                      liveBPController: liveStreamBetterPlayerController,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }).toList(),
                      ),
                      // Header
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ButtonGoBack(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ButtonChangeLiveChannels(
                    liveController: _liveController,
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
