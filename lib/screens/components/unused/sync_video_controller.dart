// import 'dart:async';

// import 'package:better_player/better_player.dart';
// import 'package:flutter/material.dart';

// class SyncBetterPlayerController {
//   BetterPlayerController? _controller;
//   bool _isDisposed = false;

//   BetterPlayerController get controller {
//     if (_controller == null || _isDisposed) {
//       throw StateError('Controller not available');
//     }
//     return _controller!;
//   }

//   SyncBetterPlayerController(String videoUrl) {
//     debugPrint('Creating SyncBetterPlayerController for: $videoUrl');
//     _initializeController(videoUrl);
//   }

//   Future<void> _initializeController(String videoUrl) async {
//     if (_isDisposed) return;

//     try {
//       final config = BetterPlayerConfiguration(
//         aspectRatio: 16 / 9,
//         autoPlay: true, // Enable auto play to see if videos load
//         handleLifecycle: false,
//         allowedScreenSleep: false,
//         autoDetectFullscreenDeviceOrientation: false,
//         // Keep controls enabled for debugging
//         controlsConfiguration: const BetterPlayerControlsConfiguration(
//           showControls: true, // Enable controls temporarily for testing
//           enableOverflowMenu: false,
//           enablePlayPause: true,
//           enableMute: true,
//           enableFullscreen: false,
//           enablePip: false,
//           enablePlaybackSpeed: false,
//           enableProgressText: true,
//           enableProgressBar: true,
//           enableSkips: false,
//           enableAudioTracks: false,
//           enableSubtitles: false,
//           enableQualities: false,
//         ),
//         errorBuilder: (context, errorMessage) {
//           return Container(
//             color: Colors.black,
//             child: const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.error_outline,
//                     color: Colors.red,
//                     size: 48,
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'Video unavailable',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Failed to load video',
//                     style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );

//       final dataSource = BetterPlayerDataSource(
//         BetterPlayerDataSourceType.network, 
//         videoUrl,
//         liveStream: false, // This is for recorded videos
//         videoFormat: BetterPlayerVideoFormat.other, // Let it auto-detect
//         bufferingConfiguration: const BetterPlayerBufferingConfiguration(
//           minBufferMs: 3000,
//           maxBufferMs: 15000,
//           bufferForPlaybackMs: 2000,
//           bufferForPlaybackAfterRebufferMs: 3000,
//         ),
//       );

//       if (!_isDisposed) {
//         debugPrint('Creating BetterPlayerController with dataSource: ${dataSource.url}');
//         _controller = BetterPlayerController(
//           config,
//           betterPlayerDataSource: dataSource,
//         );
//         debugPrint('BetterPlayerController created successfully');
//       }
      
//     } catch (e) {
//       if (!_isDisposed) {
//         // Create minimal fallback controller
//         try {
//           _controller = BetterPlayerController(
//             const BetterPlayerConfiguration(
//               aspectRatio: 16 / 9,
//               autoPlay: false,
//               handleLifecycle: false,
//             ),
//           );
//         } catch (e) {
//           // Even fallback failed - controller will remain null
//         }
//       }
//     }
//   }

//   void dispose() {
//     if (_isDisposed) return;
    
//     _isDisposed = true;
    
//     if (_controller != null) {
//       Timer(const Duration(milliseconds: 100), () {
//         try {
//           _controller?.dispose();
//         } catch (e) {
//           // Ignore dispose errors
//         }
//         _controller = null;
//       });
//     }
//   }
// }