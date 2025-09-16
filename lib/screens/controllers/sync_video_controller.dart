import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:multi_video/screens/const/sync_const.dart';
import 'package:multi_video/screens/controllers/sync_video_better_player_controller.dart';

class SyncVideoController extends ChangeNotifier {
  // Private variables
  final List<String> _selectedChannels = [];
  final Map<int, SyncVideoBetterPlayerController> _controllers = {};
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  // Selected channels
  List<String> get selectedChannels => List.from(_selectedChannels);
  bool isChannelSelected(String channel) => _selectedChannels.contains(channel);
  int get selectedChannelsCount => _selectedChannels.length;

  // Controllers
  Map<int, SyncVideoBetterPlayerController> get controllers => _controllers;
  SyncVideoBetterPlayerController? getController(int channel) => _controllers[channel];

  // Playback state
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get total => _total;
  BetterPlayerController? get masterController => _controllers.values.firstOrNull?.controller;

  // Channel management
  void toggleChannel(String channel) {
    if (_selectedChannels.contains(channel)) {
      _selectedChannels.remove(channel);
    } else if (_selectedChannels.length < maxChannelsToShow) {
      _selectedChannels.add(channel);
    } else {
      // Opcional: throw exception ou callback de erro
      return;
    }
    notifyListeners();
  }

  void clearSelectedChannels() {
    _selectedChannels.clear();
    notifyListeners();
  }

  // Playback control
  void addController(int channel, SyncVideoBetterPlayerController controller) {
    _controllers[channel] = controller;
    notifyListeners();
  }

  void removeController(int channel) {
    _controllers[channel]?.dispose();
    _controllers.remove(channel);
    notifyListeners();
  }

  // Playback position
  void updatePosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  void updateTotal(Duration total) {
    _total = total;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}