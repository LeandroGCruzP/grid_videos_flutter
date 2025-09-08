import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multi_video/screens/live_stream_page.dart';
import 'package:multi_video/screens/sync_video_page.dart';

void main() {
  // Global error handler to prevent crashes
  runZonedGuarded(() {
    runApp(const MaterialApp(title: 'Navigation Basics', home: FirstRoute()));
  }, (error, stackTrace) {
    // Log error but don't crash the app
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}

class FirstRoute extends StatelessWidget {
  const FirstRoute({super.key});

  final liveUrl = "https://live-hls-web-aje.getaj.net/AJE/01.m3u8";
  
  final videoUrl1 = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  final videoUrl2 = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4";
  final videoUrl3 = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4";

  void _openLives(BuildContext context, List<String> urls) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LiveStreamPage(urls: urls)),
    );
  }

  void _openSyncVideos(BuildContext context, List<String> urls) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SyncVideoPage(urls: urls)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                child: const Text('Lives'), 
                onPressed: () => _openLives(context, [liveUrl, liveUrl, liveUrl, liveUrl, liveUrl, liveUrl])
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Sync videos'), 
                onPressed: () => _openSyncVideos(context, [videoUrl1, videoUrl2, videoUrl3, videoUrl1, videoUrl2, videoUrl3])
              ),
            ],
          ),
        ),
      ),
    );
  }
}
