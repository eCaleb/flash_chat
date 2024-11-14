import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  late String text;
  late Color buttonColor;
  late VoidCallback onPressed;

  RoundedButton({required this.buttonColor, required this.onPressed, required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Material(
        elevation: 5.0,
        color: buttonColor,
        borderRadius: BorderRadius.circular(30.0),
        child: MaterialButton(
          onPressed: onPressed,
          minWidth: 200.0,
          height: 42.0,
          child: Text(text,style: const TextStyle(color:Color.fromARGB(255, 91, 90, 90)),),
        ),
      ),
    );
  }
}
