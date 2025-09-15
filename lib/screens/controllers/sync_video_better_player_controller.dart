import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';

class SyncVideoBetterPlayerController {
  BetterPlayerController? _controller;
  bool _isDisposed = false;
  bool _hasInitializationError = false;
  Timer? _errorCheckTimer;

  BetterPlayerController get controller {
    if (_controller == null || _isDisposed || _hasInitializationError) {
      throw StateError('Controller not available');
    }
    return _controller!;
  }
  
  bool get hasError => _hasInitializationError;
  bool get isReady => _controller != null && !_isDisposed && !_hasInitializationError;

  SyncVideoBetterPlayerController(String videoUrl) {
    _initializeController(videoUrl);
  }

  Future<void> _initializeController(String videoUrl) async {
    if (_isDisposed) return;

    try {
      final config = _createSyncVideoConfig();
      final dataSource = _createSyncVideoDataSource(videoUrl);

      if (!_isDisposed) {
        _controller = BetterPlayerController(
          config,
          betterPlayerDataSource: dataSource,
        );

        _controller!.setVolume(0.0);
        // _controller!.setControlsVisibility(false);
        
        // Start monitoring for early codec errors
        _startErrorMonitoring();
      }
      
    } catch (e) {
      debugPrint('Controller initialization failed: $e');
      if (!_isDisposed) {
        _hasInitializationError = true;
      }
    }
  }
  
  void _startErrorMonitoring() {
    // Check for codec errors periodically during the first few seconds
    _errorCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      try {
        // Simple check - if controller becomes null, it's likely an error
        if (_controller == null) {
          debugPrint('Controller became null - possible initialization failure');
          _hasInitializationError = true;
          timer.cancel();
          return;
        }
        
        // Try to access basic controller properties
        try {
          _controller!.isPlaying();
          // If we can access isPlaying without error, controller is likely ok
          
          // Stop monitoring after reasonable time if no errors
          if (timer.tick > 8) { // 4 seconds (500ms * 8)
            debugPrint('Video monitoring completed - no errors detected');
            timer.cancel();
            return;
          }
        } catch (controllerError) {
          // If accessing basic properties fails, likely a codec/initialization error
          debugPrint('Controller access failed - codec error likely: $controllerError');
          _hasInitializationError = true;
          timer.cancel();
          return;
        }
        
      } catch (e) {
        debugPrint('Error during monitoring: $e');
        _hasInitializationError = true;
        timer.cancel();
      }
    });
  }


  BetterPlayerConfiguration _createSyncVideoConfig() {
    return const BetterPlayerConfiguration(
      fit: BoxFit.contain,
      autoPlay: true,
      startAt: Duration.zero,
      handleLifecycle: false,
      allowedScreenSleep: true,
      autoDetectFullscreenDeviceOrientation: false,
      deviceOrientationsAfterFullScreen: [],
      controlsConfiguration: BetterPlayerControlsConfiguration(
        // showControls: false,
        // controlsHideTime: Duration(seconds: 10000),
        enableOverflowMenu: false,
        enablePlayPause: false,
        enableMute: false,
        enableFullscreen: true,
        enablePip: false,
        enablePlaybackSpeed: false,
        enableProgressText: true,
        enableProgressBar: true,
        enableSkips: false,
        enableAudioTracks: false,
        enableSubtitles: false,
        enableQualities: false,
      ),
    );
  }


  BetterPlayerDataSource _createSyncVideoDataSource(String videoUrl) {
    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      videoUrl,
      liveStream: false,
      videoFormat: BetterPlayerVideoFormat.other,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 500,
        maxBufferMs: 2000,
        bufferForPlaybackMs: 200,
        bufferForPlaybackAfterRebufferMs: 500,
      ),
      headers: {
        'Accept': 'video/mp4;q=0.5, video/webm;q=0.3, video/*;q=0.1',
        'User-Agent': 'Flutter-OptimizedPlayer/1.0',
        'Range': 'bytes=0-',
      },
    );
  }

  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    _errorCheckTimer?.cancel();
    
    if (_controller != null) {
      Timer(const Duration(milliseconds: 100), () {
        try {
          _controller?.dispose();
        } catch (e) {
          // Ignore dispose errors
        }
        _controller = null;
      });
    }
  }
}
