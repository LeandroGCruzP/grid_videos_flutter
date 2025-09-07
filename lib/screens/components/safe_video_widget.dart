import 'dart:async';

import 'package:flutter/material.dart';

import 'video.dart';

class SafeVideoWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onTap;

  const SafeVideoWidget({super.key, required this.videoUrl, this.onTap});

  @override
  State<SafeVideoWidget> createState() => _SafeVideoWidgetState();
}

class _SafeVideoWidgetState extends State<SafeVideoWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = 'Connection failed';

  @override
  void initState() {
    super.initState();
    _initializeWithDelay();
  }

  Future<void> _initializeWithDelay() async {
    // Quick validation and setup
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      // Simple URL validation
      if (widget.videoUrl.isEmpty || 
          (!widget.videoUrl.startsWith('http') && !widget.videoUrl.startsWith('https'))) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Invalid URL';
        });
        return;
      }
      
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    }
  }

  void _onVideoError() {
    if (mounted && !_hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Stream unavailable';
      });
    }
  }

  void _performManualRetry() {
// Reset auto retry counter
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _initializeWithDelay();
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.signal_wifi_off,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Live unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 80,
              height: 24,
              child: ElevatedButton(
                onPressed: _performManualRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
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
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Connecting...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
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
    } else {
      content = VideoWidget(
        videoUrl: widget.videoUrl,
        onTap: widget.onTap,
        onError: _onVideoError,
      );
    }

    return content;
  }
}