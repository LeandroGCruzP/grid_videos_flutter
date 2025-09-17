import 'package:flutter/material.dart';
import 'package:multi_video/screens/const/sync_const.dart';
import 'package:multi_video/screens/controllers/sync_video_better_player_controller.dart';

typedef ControllerFactory = SyncVideoBetterPlayerController Function(int channel, String url);
typedef ControllerDisposer = void Function(int channel);

class SyncVideoController extends ChangeNotifier {
  final List<int> _selectedChannels = [];
  final List<int> _allChannelsKeys = [];
  final Map<int, String> _channelUrls = {};

  ControllerFactory? _controllerFactory;
  ControllerDisposer? _controllerDisposer;

  List<int> get selectedChannels => List.from(_selectedChannels);
  List<int> get allChannelsKeys => List.from(_allChannelsKeys);
  bool isChannelSelected(int channel) => _selectedChannels.contains(channel);

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
    } else if (_selectedChannels.length < maxChannelsToShow) {
      _selectedChannels.add(channel);
      notifyListeners();

      final url = _channelUrls[channel];
      if (_controllerFactory != null && url != null) {
        _controllerFactory!(channel, url);
      }
    } else {
      debugPrint('❌ Limite de canais atingido: $maxChannelsToShow');
    }
  }

  void addChannel(int channel, String url) {
    if (!_allChannelsKeys.contains(channel)) {
      _allChannelsKeys.add(channel);
      _channelUrls[channel] = url;
      notifyListeners();
    }
  }
}
