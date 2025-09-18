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

  // Sync methods
  void seekAll(Duration position) async {
    debugPrint('🟢 Seeking all controllers to position: $position');
    for (var controller in _controllers.values) {
      try {
        if (controller.isReady) {
          await controller.controller.seekTo(position);
          if (_isPlaying) {
            controller.controller.play();
          }
        }
      } catch (e) {
        debugPrint('❌ Error seeking controller: $e');
      }
    }
  }

  void playAll() {
    debugPrint('🟢 Playing all controllers');
    for (var controller in _controllers.values) {
      try {
        if (controller.isReady) {
          controller.controller.play();
        }
      } catch (e) {
        debugPrint('❌ Error playing controller: $e');
      }
    }
  }

  void pauseAll() {
    debugPrint('🟢 Pausing all controllers');
    for (var controller in _controllers.values) {
      try {
        if (controller.isReady) {
          controller.controller.pause();
        }
      } catch (e) {
        debugPrint('❌ Error pausing controller: $e');
      }
    }
  }

  void setControllerCallbacks(ControllerFactory factory, ControllerDisposer disposer) {
    _controllerFactory = factory;
    _controllerDisposer = disposer;
  }

  void registerController(int channel, SyncBPController controller) {
    debugPrint('🟢 Registering controller for channel $channel');
    _controllers[channel] = controller;
    _setupDurationListener(channel, controller);

    // Aguardar controller estar pronto antes de sincronizar
    if (_masterController != null && _currentPosition != Duration.zero) {
      debugPrint('🟢 Scheduling sync for new controller to position: $_currentPosition');
      _scheduleControllerSync(controller, _currentPosition);
    }

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

        // Primeiro recalcular master controller quando nova duração for carregada
        final previousMaster = _masterController;
        _updateMasterController();

        // Se não houve mudança de master, sincronizar com posição atual
        if (_masterController == previousMaster && _masterController != null && _currentPosition != Duration.zero) {
          debugPrint('🟢 Late scheduling sync for controller $channel to position: $_currentPosition');
          _scheduleControllerSync(controller, _currentPosition);
        }
      }
    }

    videoController?.addListener(durationListener);

    // Timeout para evitar listener infinito (10 segundos)
    _durationTimers[channel] = Timer(const Duration(seconds: 10), () {
      debugPrint('❌ Duration listener timeout for channel $channel');
      videoController?.removeListener(durationListener);
      _durationTimers.remove(channel);
    });

    debugPrint('🟢 Duration listener setup for channel $channel');
  }

  void _scheduleControllerSync(SyncBPController controller, Duration position, {int attempt = 1, int maxAttempts = 10}) {
    debugPrint('🟢 Scheduling sync attempt $attempt/$maxAttempts for position: $position');

    Timer(Duration(milliseconds: 500 * attempt), () {
      if (controller.isReady) {
        debugPrint('🟢 Controller ready, syncing to position: $position');
        _syncControllerToPosition(controller, position);
      } else if (attempt < maxAttempts) {
        debugPrint('🟢 Controller not ready, retrying in ${500 * (attempt + 1)}ms (attempt ${attempt + 1}/$maxAttempts)');
        _scheduleControllerSync(controller, position, attempt: attempt + 1, maxAttempts: maxAttempts);
      } else {
        debugPrint('❌ Controller sync failed after $maxAttempts attempts');
      }
    });
  }

  void _syncControllerToPosition(SyncBPController controller, Duration position) async {
    try {
      if (controller.isReady) {
        await controller.controller.seekTo(position);
        debugPrint('🟢 Controller synced to position: $position');

        // Se o master está tocando, tocar o novo controller também
        if (_isPlaying) {
          controller.controller.play();
          debugPrint('🟢 New controller started playing');
        } else {
          controller.controller.pause();
          debugPrint('🟢 New controller paused');
        }
      } else {
        debugPrint('❌ Cannot sync controller - not ready yet');
      }
    } catch (e) {
      debugPrint('❌ Error syncing controller to position: $e');
    }
  }

  void _scheduleNewMasterSync(SyncBPController masterController, Duration position, bool shouldPlay, {int attempt = 1, int maxAttempts = 10}) {
    debugPrint('🟢 Scheduling new master sync attempt $attempt/$maxAttempts for position: $position');

    Timer(Duration(milliseconds: 500 * attempt), () {
      if (masterController.isReady) {
        debugPrint('🟢 New master ready, syncing to position: $position');
        _syncNewMasterToPosition(masterController, position, shouldPlay);
      } else if (attempt < maxAttempts) {
        debugPrint('🟢 New master not ready, retrying in ${500 * (attempt + 1)}ms (attempt ${attempt + 1}/$maxAttempts)');
        _scheduleNewMasterSync(masterController, position, shouldPlay, attempt: attempt + 1, maxAttempts: maxAttempts);
      } else {
        debugPrint('❌ New master sync failed after $maxAttempts attempts');
      }
    });
  }

  void _syncNewMasterToPosition(SyncBPController masterController, Duration position, bool shouldPlay) async {
    try {
      if (masterController.isReady) {
        await masterController.controller.seekTo(position);
        _currentPosition = position;
        debugPrint('🟢 New master synced to inherited position: $position');

        if (shouldPlay) {
          masterController.controller.play();
          _isPlaying = true;
          debugPrint('🟢 New master started playing');
        } else {
          masterController.controller.pause();
          _isPlaying = false;
          debugPrint('🟢 New master paused');
        }

        // Também sincronizar todos os outros controllers com delay
        for (var entry in _controllers.entries) {
          if (entry.value != masterController) {
            _scheduleControllerSync(entry.value, position);
          }
        }
      } else {
        debugPrint('❌ Cannot sync new master - not ready yet');
      }
    } catch (e) {
      debugPrint('❌ Error syncing new master to position: $e');
    }
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
        final previousPosition = _currentPosition;
        final wasPlaying = _isPlaying;

        debugPrint('🟢 Setting new master controller with duration: $maxDuration');
        debugPrint('🟢 Previous position to inherit: $previousPosition, was playing: $wasPlaying');

        _masterController?.removeEventsListener(_onPlayerEvent);
        _masterController = masterCandidate.controller;
        _masterController?.addEventsListener(_onPlayerEvent);
        _totalDuration = maxDuration;

        // Sincronizar novo master com posição anterior
        if (previousPosition != Duration.zero && previousPosition <= maxDuration) {
          debugPrint('🟢 Scheduling new master sync to inherited position: $previousPosition');
          _scheduleNewMasterSync(masterCandidate, previousPosition, wasPlaying);
        } else if (previousPosition > maxDuration) {
          debugPrint('🟢 Previous position ($previousPosition) exceeds new master duration ($maxDuration), seeking to end');
          _scheduleNewMasterSync(masterCandidate, maxDuration, wasPlaying);
        }

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
