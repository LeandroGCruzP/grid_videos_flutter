import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class CustomBetterPlayerController {
  BetterPlayerController? _controller;
  bool _isDisposed = false;

  BetterPlayerController get controller {
    if (_controller == null || _isDisposed) {
      throw StateError('Controller not available');
    }
    return _controller!;
  }

  CustomBetterPlayerController(String videoUrl) {
    _initializeController(videoUrl);
  }

  Future<void> _initializeController(String videoUrl) async {
    if (_isDisposed) return;

    try {
      final config = BetterPlayerConfiguration(
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

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, 
        videoUrl,
        liveStream: true,
        videoFormat: BetterPlayerVideoFormat.hls,
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 1500,
          maxBufferMs: 8000,
          bufferForPlaybackMs: 1000,
          bufferForPlaybackAfterRebufferMs: 1500,
        ),
      );

      if (!_isDisposed) {
        _controller = BetterPlayerController(
          config,
          betterPlayerDataSource: dataSource,
        );
        
        // Safely set controls after a delay
        Timer(const Duration(milliseconds: 100), () {
          if (!_isDisposed && _controller != null) {
            try {
              _controller!.setControlsEnabled(false);
            } catch (e) {
              // Ignore controls error
            }
          }
        });
      }
      
    } catch (e) {
      if (!_isDisposed) {
        // Create minimal fallback controller
        try {
          _controller = BetterPlayerController(
            const BetterPlayerConfiguration(
              aspectRatio: 16 / 9,
              autoPlay: false,
              handleLifecycle: false,
            ),
          );
        } catch (e) {
          // Even fallback failed - controller will remain null
        }
      }
    }
  }

  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
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
