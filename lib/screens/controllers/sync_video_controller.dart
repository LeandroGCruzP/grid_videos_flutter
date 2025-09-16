import 'package:flutter/material.dart';
import 'package:multi_video/screens/const/sync_const.dart';

class SyncVideoController extends ChangeNotifier {
  final List<int> _selectedChannels = [];
  final List<int> _allChannelsKeys = [];

  List<int> get selectedChannels => List.from(_selectedChannels);
  List<int> get allChannelsKeys => List.from(_allChannelsKeys);
  bool isChannelSelected(int channel) => _selectedChannels.contains(channel);

  void toggleChannel(int channel) {
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

  void addChannel(int channel) {
    if (!_allChannelsKeys.contains(channel)) {
      _allChannelsKeys.add(channel);
      notifyListeners();
    }
  }
}