import 'package:flutter/material.dart';

class SquareBox extends StatelessWidget {
  final String imagePath;
  final Function()? onTap;
  final Color borderColor;
  final double borderWidth;
  const SquareBox({
    super.key,
    required this.imagePath,
    required this.onTap,
    this.borderColor = Colors.black,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(25),
        decoration: BoxDecoration(
          border: Border.all(
            // color: Colors.deepOrange.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(50),
          // color: Colors.gre,
        ),
        child: Image.asset(
          imagePath,
          height: 45,
        ),
      ),
    );
  }
}
