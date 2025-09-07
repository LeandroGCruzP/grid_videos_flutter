import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multi_video/screens/live_stream_page.dart';

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

  final url = "https://live-hls-web-aje.getaj.net/AJE/01.m3u8";
  final url2 = "https://ireplay.tv/test/blender.m3u8";
  final url3 = "https://www.youtube.com/watch?v=ydYDqZQpim8";

  void _openLives(BuildContext context, List<String> urls) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LiveStreamPage(urls: urls)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('First Route')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                child: const Text('Live 1'), 
                onPressed: () => _openLives(context, [url])
              ),
              ElevatedButton(
                child: const Text('Lives 2'), 
                onPressed: () => _openLives(context, [url, url2])
              ),
              ElevatedButton(
                child: const Text('Lives 3'), 
                onPressed: () => _openLives(context, [url, url2, url3])
              ),
              ElevatedButton(
                child: const Text('Lives 4'), 
                onPressed: () => _openLives(context, [url, url2, url3, url])
              ),
              ElevatedButton(
                child: const Text('Lives 5'), 
                onPressed: () => _openLives(context, [url, url2, url3, url, url2])
              ),
              ElevatedButton(
                child: const Text('Lives 6'), 
                onPressed: () => _openLives(context, [url, url2, url3, url, url2, url3])
              ),
            ],
          ),
        ),
      ),
    );
  }
}
