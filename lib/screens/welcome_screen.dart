import 'package:flutter/material.dart';
import 'package:flash_chat/screens/login_screen.dart';
import 'package:flash_chat/screens/registration_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';


import 'components/rounded_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  static const String id = 'welcome_screen';

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Color?> animationColor;
  late Animation<double> animationSize;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // ColorTween animation for background color
    animationColor = ColorTween(begin: Colors.blueGrey, end: Colors.white)
        .animate(controller);

    // Tween animation for logo size
    animationSize = Tween<double>(begin: 0, end: 100).animate(controller);

    controller.forward();

    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: animationColor.value,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: GestureDetector(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Hero(
                    tag: 'logo',
                    child: Container(
                      height: animationSize.value, // Use animationSize here
                      child: Image.asset('assets/images/logo.png'),
                    ),
                  ),
                  AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText('Flash Chat',
                          textStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 45.0,
                            fontWeight: FontWeight.bold,
                          ),
                          speed: const Duration(milliseconds: 200)),
                    ],
                    repeatForever: false,
                    totalRepeatCount: 1,
                  )
                ],
              ),
              const SizedBox(
                height: 48.0,
              ),
              RoundedButton(
                  buttonColor: Colors.lightBlueAccent,
                  onPressed: () {
                    Navigator.pushNamed(context, LoginScreen.id);
                  },
                  text: 'Log In'),
              RoundedButton(
                  buttonColor: Colors.blueAccent,
                  onPressed: () {
                    Navigator.pushNamed(context, RegistrationScreen.id);
                  },
                  text: 'Register')
            ],
          ),
        ),
      ),
    );
  }
}
