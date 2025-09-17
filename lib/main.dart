import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multi_video/screens/pages/live_stream_page.dart';
import 'package:multi_video/screens/pages/sync_video_page.dart';

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

  static List<Map<String, dynamic>> lives = [
    { "channel": 1, "url": "https://live-hls-web-aje.getaj.net/AJE/01.m3u8"},
    { "channel": 2, "url": "https://live-hls-web-aje.getaj.net/AJE/01.m3u8"},
    { "channel": 3, "url": "https://live-hls-web-aje.getaj.net/AJE/01.m3u8"},
    { "channel": 4, "url": "https://live-hls-web-aje.getaj.net/AJE/01.m3u8"},
    { "channel": 5, "url": "https://live-hls-web-aje.getaj.net/AJE/01.m3u8"},
    { "channel": 6, "url": "https://live-hls-web-aje.getaj.net/AJE/01.m3u8"},
  ];

  static List<Map<String, dynamic>> videos = [
    { "channel": 1, "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"},
    { "channel": 2, "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"},
    { "channel": 3, "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"},
    { "channel": 4, "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"},
    { "channel": 5, "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"},
    { "channel": 6, "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4"},
  ];

  void _openLives(BuildContext context, List<Map<String, dynamic>> lives) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LiveStreamPage(lives: lives)),
    );
  }

  void _openSyncVideos(BuildContext context, List<Map<String, dynamic>> videos) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SyncVideoPage(videos: videos)),
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
                onPressed: () => _openLives(context, FirstRoute.lives)
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text('Videos'), 
                onPressed: () => _openSyncVideos(context, FirstRoute.videos)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
