import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

import '../controllers/better_player_controller.dart';

class VideoWidget extends StatefulWidget {
  final String videoUrl;

  const VideoWidget({super.key, required this.videoUrl});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late CustomBetterPlayerController _customController;

  @override
  void initState() {
    super.initState();
    _customController = CustomBetterPlayerController(widget.videoUrl);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BetterPlayer(controller: _customController.controller);
  }
}
