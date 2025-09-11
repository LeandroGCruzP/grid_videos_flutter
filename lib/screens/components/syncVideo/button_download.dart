import 'package:flutter/material.dart';

class ButtonDownload extends StatelessWidget {
  final VoidCallback? onPressed;  

  const ButtonDownload({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 33,
      height: 33,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color.fromARGB(31, 88, 88, 88), width: 1),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.download,
          color: Color(0xFF343432),
          size: 16,
        ),
      ),
    );
  }
}