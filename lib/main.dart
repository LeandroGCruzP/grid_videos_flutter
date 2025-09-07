import 'package:flutter/material.dart';
import 'package:multi_video/screens/live_stream_page.dart';

void main() {
  runApp(const MaterialApp(title: 'Navigation Basics', home: FirstRoute()));
}

class FirstRoute extends StatelessWidget {
  const FirstRoute({super.key});

  final url = "https://live-hls-web-aje.getaj.net/AJE/01.m3u8";

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Open multiple live streams'),
            ElevatedButton(
              child: const Text('Live 1'), 
              onPressed: () => _openLives(context, [url])
            ),
            ElevatedButton(
              child: const Text('Lives 2'), 
              onPressed: () => _openLives(context, [url, url])
            ),
            ElevatedButton(
              child: const Text('Lives 3'), 
              onPressed: () => _openLives(context, [url, url, url])
            ),
            ElevatedButton(
              child: const Text('Lives 4'), 
              onPressed: () => _openLives(context, [url, url, url, url])
            ),
            ElevatedButton(
              child: const Text('Lives 5'), 
              onPressed: () => _openLives(context, [url, url, url, url, url])
            ),
            ElevatedButton(
              child: const Text('Lives 6'), 
              onPressed: () => _openLives(context, [url, url, url, url, url, url])
            ),
          ],
        ),
      ),
    );
  }
}
