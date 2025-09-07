import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

import '../controllers/better_player_controller.dart';

class VideoWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onTap;
  final VoidCallback? onError;

  const VideoWidget({super.key, required this.videoUrl, this.onTap, this.onError});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  CustomBetterPlayerController? _customController;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await runZonedGuarded(() async {
      try {
        _customController = CustomBetterPlayerController(widget.videoUrl);
        
        // Wait a bit to see if initialization succeeds
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Set up a timer to check if player fails after some time
          Timer(const Duration(seconds: 8), () {
            if (mounted && _customController != null) {
              try {
                final controller = _customController?.controller;
                if (controller != null) {
                  try {
                    final videoPlayerController = controller.videoPlayerController;
                    if (videoPlayerController == null || 
                        videoPlayerController.value.hasError ||
                        videoPlayerController.value.duration == Duration.zero) {
                      // Video didn't initialize or has error - likely a network error
                      widget.onError?.call();
                    }
                  } catch (e) {
                    // Any error accessing controller means failure
                    widget.onError?.call();
                  }
                }
              } catch (e) {
                // Controller access failed - definitely an error
                widget.onError?.call();
              }
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          widget.onError?.call();
        }
      }
    }, (error, stack) {
      // Catch any uncaught error from BetterPlayer/VideoPlayer
      debugPrint('Caught uncaught error in VideoWidget: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        widget.onError?.call();
      }
    });
  }

  @override
  void dispose() {
    _customController?.dispose();
    super.dispose();
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'Live unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Connection error',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
            SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    
    if (_hasError) {
      content = _buildErrorWidget();
    } else if (_isLoading) {
      content = _buildLoadingWidget();
    } else if (_customController != null) {
      content = BetterPlayer(controller: _customController!.controller);
    } else {
      content = _buildErrorWidget();
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: content,
      );
    }
    return content;
  }
}
