import 'package:flutter/material.dart';

class ButtonChangeChannels extends StatelessWidget {
  final VoidCallback onPressed;

  const ButtonChangeChannels({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5D5D5D),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: const Size(0, 30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz, size: 16, color: Colors.white),
          SizedBox(width: 5),
          Text(
            'Trocar canais',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFFC501),
            ),
          ),
        ],
      ),
    );
  }
}