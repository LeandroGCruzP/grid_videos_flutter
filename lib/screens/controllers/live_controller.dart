import 'package:flutter/material.dart';
import 'package:multi_video/screens/const/sync_const.dart';
import 'package:multi_video/screens/controllers/live_bp_controller.dart';

typedef ControllerFactory = LiveBPController Function(int channel, String url);
typedef ControllerDisposer = void Function(int channel);

class LiveController extends ChangeNotifier {
  final List<int> _selectedChannels = [];
  final List<int> _allChannelsKeys = [];
  final Map<int, String> _channelUrls = {};
  int? _fullscreenChannel;

  ControllerFactory? _controllerFactory;
  ControllerDisposer? _controllerDisposer;

  List<int> get selectedChannels => List.from(_selectedChannels);
  List<int> get allChannelsKeys => List.from(_allChannelsKeys);
  int? get fullscreenChannel => _fullscreenChannel;
  bool isChannelSelected(int channel) => _selectedChannels.contains(channel);
  bool get isFullscreen => _fullscreenChannel != null;
  String? getChannelUrl(int channel) => _channelUrls[channel];

  void setControllerCallbacks(ControllerFactory factory, ControllerDisposer disposer) {
    _controllerFactory = factory;
    _controllerDisposer = disposer;
  }

  void toggleChannel(int channel) {
    if (_selectedChannels.contains(channel)) {
      _selectedChannels.remove(channel);
      notifyListeners();

      if (_controllerDisposer != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controllerDisposer!(channel);
        });
      }
    } else if (_selectedChannels.length < maxSyncChannelsToShow) {
      _selectedChannels.add(channel);
      notifyListeners();

      final url = _channelUrls[channel];
      if (_controllerFactory != null && url != null) {
        _controllerFactory!(channel, url);
      }
    } else {
      debugPrint('❌ Limite de canais atingido: $maxSyncChannelsToShow');
    }
  }

  void addChannel(int channel, String url) {
    if (!_allChannelsKeys.contains(channel)) {
      _allChannelsKeys.add(channel);
      _channelUrls[channel] = url;
      notifyListeners();
    }
  }

  void setFullscreenChannel(int channel) {
    if (_selectedChannels.contains(channel)) {
      _fullscreenChannel = channel;
      debugPrint('📺 Setting live fullscreen channel: $channel');
      notifyListeners();
    }
  }

  void exitFullscreen() {
    if (_fullscreenChannel != null) {
      debugPrint('↩️ Exiting live fullscreen mode');
      _fullscreenChannel = null;
      notifyListeners();
    }
  }

  void toggleFullscreen(int channel) {
    if (_fullscreenChannel == channel) {
      exitFullscreen();
    } else {
      setFullscreenChannel(channel);
    }
  }

  @override
  void dispose() {
    _selectedChannels.clear();
    _allChannelsKeys.clear();
    _channelUrls.clear();
    _fullscreenChannel = null;
    super.dispose();
  }
}
