// import 'package:better_player/better_player.dart';
// import 'package:flutter/material.dart';
// import 'package:multi_video/screens/components/syncVideo/sync_dock.dart';

// import 'simple_sync_video.dart';

// class SyncVideoLayout extends StatefulWidget {
//   final List<String> videoUrls;

//   const SyncVideoLayout({super.key, required this.videoUrls});

//   @override
//   State<SyncVideoLayout> createState() => _SyncVideoLayoutState();
// }

// class _SyncVideoLayoutState extends State<SyncVideoLayout> {
//   int _mainVideoIndex = 0;
//   bool _showDock = false;
  
//   final List<BetterPlayerController?> _controllers = [];

//   @override
//   void initState() {
//     super.initState();
//     // Initialize controllers list
//     for (int i = 0; i < widget.videoUrls.length; i++) {
//       _controllers.add(null);
//     }
//   }

//   void _setMainVideo(int index) {
//     setState(() {
//       _mainVideoIndex = index;
//       _showDock = false;
//     });
//   }

//   void _toggleDock() {
//     setState(() {
//       _showDock = !_showDock;
//     });
//   }

//   List<int> get _visibleThumbnailIndices {
//     List<int> indices = List.generate(widget.videoUrls.length, (index) => index);
//     indices.removeAt(_mainVideoIndex);
//     return indices.take(2).toList(); // Max 2 thumbnails
//   }

//   List<BetterPlayerController> get _allControllers {
//     return _controllers.where((c) => c != null).cast<BetterPlayerController>().toList();
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
//                               SimpleSyncVideo(
//                                 key: ValueKey('main_video_${widget.videoUrls[_mainVideoIndex]}_$_mainVideoIndex'),
//                                 videoUrl: widget.videoUrls[_mainVideoIndex],
//                                 onTap: _toggleDock,
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
//                             mainController: _controllers[_mainVideoIndex],
//                             allControllers: _allControllers,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
            
//             // Thumbnails
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
//                                 child: SimpleSyncVideo(
//                                   key: ValueKey('thumbnail_video_${widget.videoUrls[originalIndex]}_$originalIndex'),
//                                   videoUrl: widget.videoUrls[originalIndex],
//                                 ),
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