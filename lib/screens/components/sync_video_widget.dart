import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../controllers/sync_video_controller.dart';

class SyncVideoWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onTap;
  final VoidCallback? onError;
  final BetterPlayerController? globalController;
  final bool isMainVideo;

  const SyncVideoWidget({
    super.key, 
    required this.videoUrl, 
    this.onTap, 
    this.onError,
    this.globalController,
    this.isMainVideo = false,
  });

  @override
  State<SyncVideoWidget> createState() => _SyncVideoWidgetState();
}

class _SyncVideoWidgetState extends State<SyncVideoWidget> {
  SyncBetterPlayerController? _customController;
  bool _hasError = false;
  bool _isLoading = true;
  StreamSubscription? _globalStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      debugPrint('Initializing video: ${widget.videoUrl}');
      _customController = SyncBetterPlayerController(widget.videoUrl);
      
      // Wait a bit to see if initialization succeeds
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Video initialized successfully: ${widget.videoUrl}');
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        widget.onError?.call();
      }
    }
  }


  @override
  void dispose() {
    _globalStateSubscription?.cancel();
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
              'Video unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Failed to load',
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
              'Loading video...',
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

  // Expose controller for global sync
  BetterPlayerController? get controller => _customController?.controller;
}