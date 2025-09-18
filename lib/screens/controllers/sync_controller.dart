import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:multi_video/screens/const/sync_const.dart';
import 'package:multi_video/screens/controllers/sync_bp_controller.dart';

typedef ControllerFactory = SyncBPController Function(int channel, String url);
typedef ControllerDisposer = void Function(int channel);

class SyncController extends ChangeNotifier {
  final List<int> _selectedChannels = [];
  final List<int> _allChannelsKeys = [];
  final Map<int, String> _channelUrls = {};
  final Map<int, SyncBPController> _controllers = {};
  final Map<int, Timer?> _durationTimers = {};
  int? _fullscreenChannel;
  BetterPlayerController? _masterController;
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;

  ControllerFactory? _controllerFactory;
  ControllerDisposer? _controllerDisposer;

  List<int> get selectedChannels => List.from(_selectedChannels);
  List<int> get allChannelsKeys => List.from(_allChannelsKeys);
  int? get fullscreenChannel => _fullscreenChannel;
  bool isChannelSelected(int channel) => _selectedChannels.contains(channel);
  bool get isFullscreen => _fullscreenChannel != null;

  // Master controller getters
  BetterPlayerController? get masterController => _masterController;
  Duration get totalDuration => _totalDuration;
  Duration get currentPosition => _currentPosition;
  bool get isPlaying => _isPlaying;

  void setControllerCallbacks(ControllerFactory factory, ControllerDisposer disposer) {
    _controllerFactory = factory;
    _controllerDisposer = disposer;
  }

  void registerController(int channel, SyncBPController controller) {
    debugPrint('🟢 Registering controller for channel $channel');
    _controllers[channel] = controller;
    _setupDurationListener(channel, controller);
    _updateMasterController();
  }

  void unregisterController(int channel) {
    debugPrint('🟢 Unregistering controller for channel $channel');
    _controllers.remove(channel);
    _durationTimers[channel]?.cancel();
    _durationTimers.remove(channel);
    _updateMasterController();
  }

  void _setupDurationListener(int channel, SyncBPController controller) {
    final videoController = controller.controller.videoPlayerController;

    void durationListener() {
      final duration = videoController?.value.duration ?? Duration.zero;
      if (duration != Duration.zero) {
        debugPrint('🟢 Duration loaded for channel $channel: $duration');
        videoController?.removeListener(durationListener);
        _durationTimers[channel]?.cancel();
        _durationTimers.remove(channel);

        // Recalcular master controller quando nova duração for carregada
        _updateMasterController();
      }
    }

    videoController?.addListener(durationListener);

    // Timeout para evitar listener infinito (10 segundos)
    _durationTimers[channel] = Timer(Duration(seconds: 10), () {
      debugPrint('❌ Duration listener timeout for channel $channel');
      videoController?.removeListener(durationListener);
      _durationTimers.remove(channel);
    });

    debugPrint('🟢 Duration listener setup for channel $channel');
  }

  void _updateMasterController() {
    debugPrint('🟢 Updating master controller. Total controllers: ${_controllers.length}');

    if (_controllers.isEmpty) {
      debugPrint('🟢 No controllers available, clearing master controller');
      _masterController?.removeEventsListener(_onPlayerEvent);
      _masterController = null;
      _totalDuration = Duration.zero;
      _currentPosition = Duration.zero;
      _isPlaying = false;
      notifyListeners();
      return;
    }

    try {
      SyncBPController? masterCandidate;
      Duration maxDuration = Duration.zero;

      for (var syncBPController in _controllers.values) {
        if (syncBPController.isReady) {
          final controllerDuration =
              syncBPController.controller.videoPlayerController?.value.duration ??
                  Duration.zero;
          debugPrint('🟢 Controller duration: $controllerDuration');

          if (controllerDuration > maxDuration) {
            maxDuration = controllerDuration;
            masterCandidate = syncBPController;
          }
        }
      }

      if (masterCandidate != null && masterCandidate.controller != _masterController) {
        debugPrint('🟢 Setting new master controller with duration: $maxDuration');
        _masterController?.removeEventsListener(_onPlayerEvent);
        _masterController = masterCandidate.controller;
        _masterController?.addEventsListener(_onPlayerEvent);
        _totalDuration = maxDuration;
        debugPrint('🟢 Master controller set successfully');
        notifyListeners();
      } else if (masterCandidate == null) {
        debugPrint('❌ No master candidate found from ${_controllers.length} controllers');
      } else {
        debugPrint('🟢 Master controller unchanged (same controller)');
      }
    } catch (e) {
      debugPrint('❌ Error updating master controller: $e');
    }
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.progress:
        final newPosition = event.parameters?["progress"] ?? Duration.zero;
        final newDuration = event.parameters?["duration"] ?? Duration.zero;
        final isPlaying = _masterController?.isPlaying() ?? false;

        debugPrint('🟢 Progress event - Position: $newPosition, Duration: $newDuration, Playing: $isPlaying');

        _currentPosition = newPosition;

        if (newDuration != _totalDuration && newDuration != Duration.zero) {
          debugPrint('🟢 Duration updated from $_totalDuration to $newDuration');
          _totalDuration = newDuration;
        }

        if (isPlaying != _isPlaying) {
          debugPrint('🟢 Play state changed from $_isPlaying to $isPlaying');
          _isPlaying = isPlaying;
        }

        notifyListeners();
        break;

      case BetterPlayerEventType.play:
        debugPrint('🟢 Play event received');
        _isPlaying = true;
        notifyListeners();
        break;

      case BetterPlayerEventType.pause:
        debugPrint('🟢 Pause event received');
        _isPlaying = false;
        notifyListeners();
        break;

      case BetterPlayerEventType.finished:
        debugPrint('🟢 Finished event received');
        _isPlaying = false;
        notifyListeners();
        break;

      default:
        debugPrint('🟢 Other event received: ${event.betterPlayerEventType}');
        break;
    }
  }

  void toggleChannel(int channel) {
    debugPrint('🟢 Toggling channel $channel');

    if (_selectedChannels.contains(channel)) {
      debugPrint('🟢 Removing channel $channel from selected channels');

      // If removing the fullscreen channel, exit fullscreen first
      if (_fullscreenChannel == channel) {
        debugPrint('🟢 Exiting fullscreen for removed channel $channel');
        _fullscreenChannel = null;
      }

      _selectedChannels.remove(channel);
      unregisterController(channel);
      notifyListeners();

      if (_controllerDisposer != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint('🟢 Disposing controller for channel $channel');
          _controllerDisposer!(channel);
        });
      }
    } else if (_selectedChannels.length < maxSyncChannelsToShow) {
      debugPrint('🟢 Adding channel $channel to selected channels');
      _selectedChannels.add(channel);
      notifyListeners();

      final url = _channelUrls[channel];
      if (_controllerFactory != null && url != null) {
        debugPrint('🟢 Creating controller for channel $channel with URL: $url');
        final controller = _controllerFactory!(channel, url);
        registerController(channel, controller);
      } else {
        debugPrint('❌ Cannot create controller - factory: ${_controllerFactory != null}, url: $url');
      }
    } else {
      debugPrint('❌ Channel limit reached: $maxSyncChannelsToShow');
    }
  }

  void addChannel(int channel, String url) {
    debugPrint('🟢 Adding channel $channel with URL: $url');
    if (!_allChannelsKeys.contains(channel)) {
      _allChannelsKeys.add(channel);
      _channelUrls[channel] = url;
      debugPrint('🟢 Channel $channel added successfully');
      notifyListeners();
    } else {
      debugPrint('🟢 Channel $channel already exists');
    }
  }

  void setFullscreenChannel(int channel) {
    debugPrint('🟢 Setting fullscreen channel: $channel');
    if (_selectedChannels.contains(channel)) {
      _fullscreenChannel = channel;
      debugPrint('🟢 Fullscreen channel set to: $channel');
      notifyListeners();
    } else {
      debugPrint('❌ Cannot set fullscreen - channel $channel not selected');
    }
  }

  void exitFullscreen() {
    if (_fullscreenChannel != null) {
      debugPrint('🟢 Exiting fullscreen mode from channel $_fullscreenChannel');
      _fullscreenChannel = null;
      notifyListeners();
    } else {
      debugPrint('🟢 Already not in fullscreen mode');
    }
  }

  void toggleFullscreen(int channel) {
    debugPrint('🟢 Toggling fullscreen for channel $channel');
    if (_fullscreenChannel == channel) {
      exitFullscreen();
    } else {
      setFullscreenChannel(channel);
    }
  }

  @override
  void dispose() {
    debugPrint('🟢 Disposing SyncController');
    _masterController?.removeEventsListener(_onPlayerEvent);
    _masterController = null;

    // Cancel all duration timers
    for (var timer in _durationTimers.values) {
      timer?.cancel();
    }
    _durationTimers.clear();

    _controllers.clear();
    _selectedChannels.clear();
    _allChannelsKeys.clear();
    _channelUrls.clear();
    _fullscreenChannel = null;
    debugPrint('🟢 SyncController disposed successfully');
    super.dispose();
  }
}
