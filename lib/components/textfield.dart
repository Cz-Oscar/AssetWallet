import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final controller; // to access information inside this text field
  final String hintText; // to give hint what to write in text field
  final bool obscureText; // to hide typing password

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black87),
            ),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.deepOrange.shade300,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(10)),
            fillColor: Colors.white,
            filled: true,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.black)),
      ),
    );
  }
}
