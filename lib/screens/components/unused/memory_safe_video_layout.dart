// import 'package:better_player/better_player.dart';
// import 'package:flutter/material.dart';
// import 'package:multi_video/screens/components/syncVideo/sync_dock.dart';

// class MemorySafeVideoLayout extends StatefulWidget {
//   final List<String> videoUrls;

//   const MemorySafeVideoLayout({super.key, required this.videoUrls});

//   @override
//   State<MemorySafeVideoLayout> createState() => _MemorySafeVideoLayoutState();
// }

// class _MemorySafeVideoLayoutState extends State<MemorySafeVideoLayout> {
//   int _mainVideoIndex = 0;
//   bool _showDock = false;
//   BetterPlayerController? _mainController;

//   void _setMainVideo(int index) {
//     if (index != _mainVideoIndex) {
//       setState(() {
//         _mainVideoIndex = index;
//         _showDock = false;
//         _mainController = null; // Reset controller to force recreation
//       });
//     }
//   }

//   void _toggleDock() {
//     setState(() {
//       _showDock = !_showDock;
//     });
//   }

//   void _onMainVideoReady(BetterPlayerController? controller) {
//     setState(() {
//       _mainController = controller;
//     });
//   }

//   List<int> get _visibleThumbnailIndices {
//     List<int> indices = List.generate(widget.videoUrls.length, (index) => index);
//     indices.removeAt(_mainVideoIndex);
//     return indices.take(2).toList(); // Max 2 thumbnails
//   }

//   Widget _buildThumbnailPlaceholder(int index) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[800],
//         borderRadius: BorderRadius.circular(5),
//       ),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.play_circle_outline,
//               color: Colors.white.withOpacity(0.7),
//               size: 40,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'VIDEO ${index + 1}',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.7),
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.videoUrls.isEmpty) {
//       return const Center(child: Text('No videos available'));
//     }

//     return Stack(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               flex: 4,
//               child: Container(
//                 margin: const EdgeInsets.all(4),
//                 child: Column(
//                   children: [
//                     Expanded(
//                       flex: _showDock ? 3 : 4,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey, width: 2),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(5),
//                           child: Stack(
//                             children: [
//                               // Only load the main video to save memory
//                               SimpleSyncVideoWithCallback(
//                                 key: ValueKey('main_video_${widget.videoUrls[_mainVideoIndex]}_$_mainVideoIndex'),
//                                 videoUrl: widget.videoUrls[_mainVideoIndex],
//                                 onTap: _toggleDock,
//                                 onControllerReady: _onMainVideoReady,
//                               ),
//                               Positioned(
//                                 top: 8,
//                                 left: 8,
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.red.withOpacity(0.8),
//                                     borderRadius: BorderRadius.circular(4),
//                                   ),
//                                   child: Text(
//                                     'VIDEO ${_mainVideoIndex + 1}',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     if (_showDock)
//                       Expanded(
//                         flex: 1,
//                         child: Container(
//                           margin: const EdgeInsets.only(top: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.black.withOpacity(0.8),
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.grey, width: 1),
//                           ),
//                           child: SyncDock(
//                             mainController: _mainController,
//                             allControllers: _mainController != null ? [_mainController!] : [],
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
            
//             // Thumbnails (static placeholders to save memory)
//             if (widget.videoUrls.length > 1)
//               Expanded(
//                 flex: 1,
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 4, top: 4, bottom: 4),
//                   child: Column(
//                     children: _visibleThumbnailIndices.map((originalIndex) {
//                       return Expanded(
//                         child: Container(
//                           margin: const EdgeInsets.only(bottom: 4),
//                           child: GestureDetector(
//                             onTap: () => _setMainVideo(originalIndex),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: Colors.grey, width: 2),
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(5),
//                                 // Use placeholder instead of actual video to save memory
//                                 child: _buildThumbnailPlaceholder(originalIndex),
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),
//           ],
//         ),
        
//         // Back button when dock is visible
//         if (_showDock)
//           Positioned(
//             top: 16,
//             left: 16,
//             child: Container(
//               width: 48,
//               height: 48,
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.7),
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
//               ),
//               child: IconButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 icon: const Icon(
//                   Icons.arrow_back,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// // Enhanced SimpleSyncVideo with controller callback
// class SimpleSyncVideoWithCallback extends StatefulWidget {
//   final String videoUrl;
//   final VoidCallback? onTap;
//   final Function(BetterPlayerController?)? onControllerReady;

//   const SimpleSyncVideoWithCallback({
//     super.key, 
//     required this.videoUrl, 
//     this.onTap,
//     this.onControllerReady,
//   });

//   @override
//   State<SimpleSyncVideoWithCallback> createState() => _SimpleSyncVideoWithCallbackState();
// }

// class _SimpleSyncVideoWithCallbackState extends State<SimpleSyncVideoWithCallback> {
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
//         autoPlay: false,
//         handleLifecycle: false,
//         // Reduce resource usage for memory optimization
//         deviceOrientationsAfterFullScreen: [],
//         allowedScreenSleep: true,
//       );

//       final dataSource = BetterPlayerDataSource(
//         BetterPlayerDataSourceType.network,
//         widget.videoUrl,
//         liveStream: false,
//         // Optimize for lower memory usage
//         videoFormat: BetterPlayerVideoFormat.other,
//         bufferingConfiguration: const BetterPlayerBufferingConfiguration(
//           minBufferMs: 1000,        // Reduced buffer
//           maxBufferMs: 5000,        // Reduced max buffer
//           bufferForPlaybackMs: 500, // Minimal playback buffer
//           bufferForPlaybackAfterRebufferMs: 1000,
//         ),
//         // Request lower quality streams
//         headers: {
//           'Accept': 'video/mp4, video/webm;q=0.9, video/*;q=0.8',
//           'User-Agent': 'Flutter-LowRes-Player/1.0',
//         },
//       );

//       _controller = BetterPlayerController(config, betterPlayerDataSource: dataSource);
      
//       // Notify parent about controller
//       widget.onControllerReady?.call(_controller);
      
//       setState(() {
//         _isLoading = false;
//       });
      
//       debugPrint('Memory-safe video initialized: ${widget.videoUrl}');
//     } catch (e) {
//       debugPrint('Error initializing memory-safe video: $e');
//       setState(() {
//         _isLoading = false;
//       });
//       widget.onControllerReady?.call(null);
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
// }