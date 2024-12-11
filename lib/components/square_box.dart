import 'package:flutter/material.dart';

class SquareBox extends StatelessWidget {
  final String imagePath;
  final Function()? onTap;
  const SquareBox({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
