import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';

import '../../controllers/live_stream_better_player_controller.dart';

class LiveVideo extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onTap;
  final VoidCallback? onError;

  const LiveVideo({super.key, required this.videoUrl, this.onTap, this.onError});

  @override
  State<LiveVideo> createState() => _LiveVideoState();
}

class _LiveVideoState extends State<LiveVideo> {
  LiveStreamBetterPlayerController? _customController;
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
        _customController = LiveStreamBetterPlayerController(widget.videoUrl);
        
        // Wait for initial setup
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Monitor controller for early error detection
          Timer.periodic(const Duration(milliseconds: 300), (timer) {
            if (!mounted || _customController == null) {
              timer.cancel();
              return;
            }
            
            // Check if controller detected an error
            if (_customController!.hasError) {
              debugPrint('Early error detected by controller');
              timer.cancel();
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
                widget.onError?.call();
              }
              return;
            }
            
            // Stop monitoring after reasonable time
            if (timer.tick > 20) { // 6 seconds
              timer.cancel();
            }
          });
        }
      } catch (e) {
        debugPrint('Player initialization failed: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          widget.onError?.call();
        }
      }
    }, (error, stack) {
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
              'Live indisponível',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Erro de conexão',
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
              'Carregando...',
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
