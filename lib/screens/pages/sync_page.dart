import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_video/screens/components/button_go_back.dart';
import 'package:multi_video/screens/components/empty_selected_channels.dart';
import 'package:multi_video/screens/components/sync/button_download.dart';
import 'package:multi_video/screens/components/sync/sync_card.dart';
import 'package:multi_video/screens/components/sync/sync_dock.dart';
import 'package:multi_video/screens/const/sync_const.dart';
import 'package:multi_video/screens/controllers/sync_bp_controller.dart';
import 'package:multi_video/screens/controllers/sync_controller.dart';

class SyncPage extends StatefulWidget {
  final List<Map<String, dynamic>> videos;

  const SyncPage({super.key, required this.videos});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  late SyncController _syncController;
  final Map<int, SyncBPController> _syncBPControllers = {};

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _syncController = SyncController();

    // _syncController.addListener(() {
    //   debugPrint('🚀 Selected channels: ${_syncController.selectedChannels}');
    //   debugPrint('🚀 All channels: ${_syncController.allChannelsKeys}');
    // });

    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    _syncController.setControllerCallbacks(
      _createController,
      _disposeController,
    );

    for (final video in widget.videos) {
      final channel = video["channel"];
      final url = video["url"];
      _syncController.addChannel(channel, url);
    }

    for (int i = 0; i < widget.videos.length && i < maxSyncChannelsToShow; i++) {
      final video = widget.videos[i];
      final channel = video["channel"];
      _syncController.toggleChannel(channel);
    }
  }

  SyncBPController _createController(int channel, String url) {
    // debugPrint('✅ Creating controller for channel $channel with URL: $url');
    final controller = SyncBPController(url);
    _syncBPControllers[channel] = controller;
    return controller;
  }

  void _disposeController(int channel) {
    final controller = _syncBPControllers.remove(channel);
    controller?.dispose();
  }

  @override
  void dispose() {
    debugPrint('🔄 Disposing SyncVideoPage...');

    // Step 1: Dispose all video controllers first to free resources
    final controllerKeys = _syncBPControllers.keys.toList();
    for (final channel in controllerKeys) {
      _syncBPControllers[channel]?.dispose();
    }
    _syncBPControllers.clear();

    // Step 2: Dispose sync controller
    try {
      _syncController.dispose();
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

  Widget _buildGridView() {
    if (_syncController.selectedChannels.isEmpty) {
      return const EmptySelectedChannels();
    }

    return Row(
      children: _syncController.selectedChannels.asMap().entries.map((entry) {
        final index = entry.key;
        final channel = entry.value;
        final syncVideoBetterPlayerController = _syncBPControllers[channel];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < _syncController.selectedChannels.length - 1 ? 4.0 : 0),
            child: syncVideoBetterPlayerController != null
                ? SyncCard(
                    key: ValueKey(channel),
                    syncBPController: syncVideoBetterPlayerController,
                    channel: channel,
                    onTap: () => _syncController.toggleFullscreen(channel),
                  )
                : const SizedBox.shrink(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFullscreenView() {
    final fullscreenChannel = _syncController.fullscreenChannel;
    if (fullscreenChannel == null) return const SizedBox.shrink();

    final syncVideoBetterPlayerController = _syncBPControllers[fullscreenChannel];
    if (syncVideoBetterPlayerController == null) return const SizedBox.shrink();

    return SyncCard(
      key: ValueKey('fullscreen_$fullscreenChannel'),
      syncBPController: syncVideoBetterPlayerController,
      channel: fullscreenChannel,
      onTap: () => _syncController.exitFullscreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return const Center(child: Text('No videos available'));
    }
    
    return AnimatedBuilder(
      animation: _syncController,
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
                      // Video display area
                      _syncController.isFullscreen
                          ? _buildFullscreenView()
                          : _buildGridView(),
                      // Header
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ButtonGoBack(),
                            ButtonDownload(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SyncDock(
                  syncBPControllers: _syncBPControllers,
                  syncController: _syncController,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}