// import 'package:flutter/material.dart';

// class VideoGrid extends StatelessWidget {
//   final List<String> videoUrls;

//   const VideoGrid({super.key, required this.videoUrls});

//   int getCrossAxisCount() {
//     if (videoUrls.length == 1) {
//       return 1;
//     } else if (videoUrls.length <= 4) {
//       return 2;
//     } else if (videoUrls.length <= 6) {
//       return 3;
//     } else {
//       return 4;
//     }
//   }
//   final double _spacing = 6.0;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox.expand(
//       child: GridView.builder(
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: getCrossAxisCount(), // Determine the number of columns based on the number of videos
//           mainAxisExtent: 200, // Fixed height for each video container
//           crossAxisSpacing: _spacing, // Spacing between columns
//           mainAxisSpacing: _spacing, // Spacing between rows
//         ),
//         itemCount: videoUrls.length,
//         itemBuilder: (context, index) {
//           return Container(
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.black, width: 1),
//             ),
//             child: Text('Video ${index + 1}'),
//             // child: VideoWidget(videoUrl: videoUrls[index]),
//           );
//         },
//       ),
//     );
//   }
// }
