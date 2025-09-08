import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_video/screens/components/liveStream/live_stream_layout.dart';

class LiveStreamPage extends StatefulWidget {
  final List<String> urls;

  const LiveStreamPage({super.key, required this.urls});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
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
      backgroundColor: Colors.black, // Set background color
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: LiveStreamLayout(videoUrls: widget.urls),
      ),
    );
  }
}