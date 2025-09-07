import 'package:better_player/better_player.dart';

class CustomBetterPlayerController {
  late BetterPlayerController controller;

  CustomBetterPlayerController(String videoUrl) {
    const config = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      autoPlay: true,
    );

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      videoUrl,
      liveStream: true
    );
    
    controller = BetterPlayerController(
      config,
      betterPlayerDataSource: dataSource,
    );
  }

  void dispose() {
    controller.dispose();
  }
}