import 'package:flutter/material.dart';

class ChannelName extends StatelessWidget {
  final int channelNumber;

  const ChannelName({super.key, required this.channelNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF3D3D3C),
          borderRadius: BorderRadius.circular(35),
        ),
        child: Text(
          'Canal $channelNumber',
          style: const TextStyle(
            color: Color(0xFFFFC501),
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}