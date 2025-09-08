// import 'package:better_player/better_player.dart';
// import 'package:flutter/material.dart';

// class SimpleSyncVideo extends StatefulWidget {
//   final String videoUrl;
//   final VoidCallback? onTap;

//   const SimpleSyncVideo({super.key, required this.videoUrl, this.onTap});

//   @override
//   State<SimpleSyncVideo> createState() => _SimpleSyncVideoState();
// }

// class _SimpleSyncVideoState extends State<SimpleSyncVideo> {
//   BetterPlayerController? _controller;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _initializePlayer();
//   }

//   void _initializePlayer() {
//     try {
//       const config = BetterPlayerConfiguration(
//         aspectRatio: 16 / 9,
//         autoPlay: true,
//         handleLifecycle: false,
//       );

//       final dataSource = BetterPlayerDataSource(
//         BetterPlayerDataSourceType.network,
//         widget.videoUrl,
//         liveStream: false,
//       );

//       _controller = BetterPlayerController(config, betterPlayerDataSource: dataSource);
      
//       setState(() {
//         _isLoading = false;
//       });
      
//       debugPrint('Simple video initialized: ${widget.videoUrl}');
//     } catch (e) {
//       debugPrint('Error initializing simple video: $e');
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Container(
//         color: Colors.black,
//         child: const Center(
//           child: CircularProgressIndicator(color: Colors.white),
//         ),
//       );
//     }

//     if (_controller == null) {
//       return Container(
//         color: Colors.black,
//         child: const Center(
//           child: Text('Failed to load video', style: TextStyle(color: Colors.white)),
//         ),
//       );
//     }

//     Widget player = BetterPlayer(controller: _controller!);

//     if (widget.onTap != null) {
//       return GestureDetector(
//         onTap: widget.onTap,
//         child: player,
//       );
//     }

//     return player;
//   }

//   BetterPlayerController? get controller => _controller;
// }