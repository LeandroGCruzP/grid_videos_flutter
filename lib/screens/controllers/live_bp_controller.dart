import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';

class LiveBPController {
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

  LiveBPController(String videoUrl) {
    _initializeController(videoUrl);
  }

  Future<void> _initializeController(String videoUrl) async {
    if (_isDisposed) return;

    try {
      final config = _createLiveStreamConfig();
      final dataSource = _createLiveStreamDataSource(videoUrl);

      if (!_isDisposed) {
        _controller = BetterPlayerController(
          config,
          betterPlayerDataSource: dataSource,
        );

        // Configure controller for live stream
        _controller!.setControlsEnabled(false);
        _controller!.play();
        
        // Start monitoring for early codec errors
        _startErrorMonitoring();
      }
      
    } catch (e) {
      debugPrint('❌ Controller initialization failed: $e');
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
          debugPrint('❌ Controller became null - possible initialization failure');
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
            debugPrint('✅ Video monitoring completed - no errors detected');
            timer.cancel();
            return;
          }
        } catch (controllerError) {
          // If accessing basic properties fails, likely a codec/initialization error
          debugPrint('❌ Controller access failed - codec error likely: $controllerError');
          _hasInitializationError = true;
          timer.cancel();
          return;
        }
        
      } catch (e) {
        debugPrint('❌ Error during monitoring: $e');
        _hasInitializationError = true;
        timer.cancel();
      }
    });
  }

  BetterPlayerConfiguration _createLiveStreamConfig() {
    return BetterPlayerConfiguration(
      autoDispose: false,
      fit: BoxFit.contain,
      autoPlay: true,
      handleLifecycle: false,
      allowedScreenSleep: false,
      autoDetectFullscreenDeviceOrientation: false,
      errorBuilder: (context, errorMessage) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Live unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Connection error',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  BetterPlayerDataSource _createLiveStreamDataSource(String videoUrl) {
    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.network, 
      videoUrl,
      liveStream: true,
      videoFormat: BetterPlayerVideoFormat.hls,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 2000,
        maxBufferMs: 10000,
        bufferForPlaybackMs: 1000,
        bufferForPlaybackAfterRebufferMs: 2000,
      ),
      videoExtension: 'm3u8',
    );
  }


  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    // Cancel monitoring timer first
    _errorCheckTimer?.cancel();
    _errorCheckTimer = null;

    if (_controller != null) {
      try {
        // Stop playback to release network resources
        _controller?.pause();

        // Clear cache to free memory
        _controller?.clearCache();

        // Dispose controller (we have full control with autoDispose: false)
        _controller?.dispose(forceDispose: true);

        debugPrint('✅ LiveStream BetterPlayer controller disposed successfully');
      } catch (e) {
        debugPrint('❌ Error disposing LiveStream BetterPlayer controller: $e');
      } finally {
        // Always clear reference
        _controller = null;
      }
    }
  }
}
