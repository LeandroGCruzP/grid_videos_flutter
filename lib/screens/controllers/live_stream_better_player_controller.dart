import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class LiveStreamBetterPlayerController {
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

  LiveStreamBetterPlayerController(String videoUrl) {
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
        Timer(const Duration(milliseconds: 100), () {
          if (!_isDisposed && _controller != null) {
            try {
              _controller!.setControlsEnabled(false);
              _controller!.play();
            } catch (e) {
              debugPrint('Error configuring controller: $e');
            }
          }
        });
        
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

  BetterPlayerConfiguration _createLiveStreamConfig() {
    return BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
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
