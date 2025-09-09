import 'package:flutter/material.dart';

class ButtonGoBack extends StatelessWidget {
  const ButtonGoBack({super.key});

  void _onPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: const Color.fromARGB(31, 88, 88, 88), width: 1),
      ),
      child: IconButton(
        onPressed: () => _onPressed(context),
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}