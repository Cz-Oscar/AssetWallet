import 'package:flutter/material.dart';

class SquareBox extends StatelessWidget {
  final String imagePath;
  const SquareBox({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(50),
        // color: Colors.grey,
      ),
      child: Image.asset(
        imagePath,
        height: 45,
      ),
    );
  }
}
