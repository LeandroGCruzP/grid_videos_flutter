import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:multi_video/screens/components/liveStream/live_video.dart';

class LiveNetworkSafeVideo extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onTap;

  const LiveNetworkSafeVideo({super.key, required this.videoUrl, this.onTap});

  @override
  State<LiveNetworkSafeVideo> createState() => _LiveNetworkSafeVideoState();
}

class _LiveNetworkSafeVideoState extends State<LiveNetworkSafeVideo> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _urlTested = false;
  String _errorMessage = 'Connection failed';

  @override
  void initState() {
    super.initState();
    _testNetworkConnection();
  }

  Future<void> _testNetworkConnection() async {
    try {
      // Quick basic validation
      if (widget.videoUrl.isEmpty || 
          (!widget.videoUrl.startsWith('http') && !widget.videoUrl.startsWith('https'))) {
        _showError('Invalid URL');
        return;
      }

      // Try to connect to the URL host first
      final uri = Uri.parse(widget.videoUrl);
      final host = uri.host;
      
      if (host.isEmpty) {
        _showError('Invalid host');
        return;
      }

      // Test basic connectivity with socket
      Socket? socket;
      try {
        socket = await Socket.connect(host, uri.port != 0 ? uri.port : (uri.scheme == 'https' ? 443 : 80))
            .timeout(const Duration(seconds: 5));
        
        // If we got here, basic connection works
        socket.destroy();
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _urlTested = true;
          });
        }
        
      } catch (e) {
        _showError('Cannot reach server');
        return;
      }
      
    } catch (e) {
      _showError('Network error');
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = message;
      });
    }
  }

  void _onVideoError() {
    _showError('Stream unavailable');
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _urlTested = false;
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    _testNetworkConnection();
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
                onPressed: _retry,
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
              'Testing connection...',
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
    if (_hasError) {
      return _buildErrorWidget();
    } else if (_isLoading) {
      return _buildLoadingWidget();
    } else if (_urlTested) {
      // URL is safe, proceed with video player
      return LiveVideo(
        videoUrl: widget.videoUrl,
        onTap: widget.onTap,
        onError: _onVideoError,
      );
    } else {
      return _buildLoadingWidget();
    }
  }
}