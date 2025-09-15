import 'package:flutter/material.dart';

class LoadingVideo extends StatelessWidget {
  const LoadingVideo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}