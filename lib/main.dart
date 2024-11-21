import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/screens/welcome_screen.dart';
import 'package:flash_chat/screens/login_screen.dart';
import 'package:flash_chat/screens/registration_screen.dart';
import 'package:flash_chat/screens/chat_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase once at app start
  runApp(FlashChat());
}

class FlashChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Set WelcomeScreen as the initial route
      initialRoute: WelcomeScreen.id, 
      
      // Define the routes for the screens
      routes: {
        WelcomeScreen.id: (context) => WelcomeScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        RegistrationScreen.id: (context) => RegistrationScreen(),
        ChatScreen.id: (context) => ChatScreen(),
      },
    );
  }
}

//anon key : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kdXNwbWJueWtva3B0eWp2Z29qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIxNzI1MDQsImV4cCI6MjA0Nzc0ODUwNH0.ucnGUCQEc-muyM2fQr552IpZ0v0FcPrrTiqAvA-2apU
// url: https://mduspmbnykokptyjvgoj.supabase.co
