import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_video/screens/components/syncVideo/sync_video_layout.dart';

class SyncVideoPage extends StatefulWidget {
  final List<Map<String, dynamic>> videos;

  const SyncVideoPage({super.key, required this.videos});

  @override
  State<SyncVideoPage> createState() => _SyncVideoPageState();
}

class _SyncVideoPageState extends State<SyncVideoPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF484847),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: SyncVideoLayout(videos: widget.videos),
      ),
    );
  }
}