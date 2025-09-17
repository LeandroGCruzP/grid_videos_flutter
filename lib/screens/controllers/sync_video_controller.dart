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
      debugPrint('Removendo canal: $channel');
      _selectedChannels.remove(channel);

      // eliminar o controller do video associado a esse canal
    } else if (_selectedChannels.length < maxChannelsToShow) {
      debugPrint('Adicionando canal: $channel');
      _selectedChannels.add(channel);

      // criar o controller do video associado a esse canal
    } else {
      debugPrint('Limite de canais atingido: $maxChannelsToShow');
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