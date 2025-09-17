import 'package:flutter/material.dart';

class ChannelOption extends StatelessWidget {
  final int channel;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isDisabled;

  const ChannelOption({
    super.key,
    required this.channel,
    required this.onTap,
    this.isSelected = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF3D3D3C),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC501) : Colors.transparent, 
            width: 1
          ),
        ),
        child: Text(
          "Canal $channel",
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFC501) : isDisabled ? Colors.grey : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
