import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/constants.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:flash_chat/screens/components/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  late String email;
  late String password;
  bool _loading = false;
  String emailError = '';
  String passwordError = '';
  String generalError = '';

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  bool isValidPassword(String password) {
    return password.length >= 6 && !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Hero(
                  tag: 'logo',
                  child: Container(
                    height: 200.0,
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),
                const SizedBox(height: 48.0),
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    email = value;
                    setState(() {
                      emailError = '';
                    });
                  },
                  decoration: kLogInEmailDecoration,
                ),
                if (emailError.isNotEmpty)
                  Text(
                    emailError,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 8.0),
                TextField(
                  obscureText: true,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    password = value;
                    setState(() {
                      passwordError = '';
                    });
                  },
                  decoration: kLogInPasswordDecoration,
                ),
                if (passwordError.isNotEmpty)
                  Text(
                    passwordError,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24.0),
                if (generalError.isNotEmpty)
                  Text(
                    generalError,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                RoundedButton(
                  buttonColor: Colors.lightBlueAccent,
                  onPressed: () async {
                    setState(() {
                      emailError = '';
                      passwordError = '';
                      generalError = '';
                    });

                    if (!isValidEmail(email)) {
                      setState(() {
                        emailError = 'Please enter a valid email.';
                      });
                      return;
                    }

                    if (!isValidPassword(password)) {
                      setState(() {
                        passwordError = 'Password must be 6+ characters without special symbols.';
                      });
                      return;
                    }

                    setState(() {
                      _loading = true;
                    });

                    try {
                      final existingUser = await _auth.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      if (existingUser != null) {
                        Navigator.pushNamed(context, ChatScreen.id);
                      }
                    } catch (e) {
                      setState(() {
                        generalError = e.toString();
                      });
                    }
 finally {
                      setState(() {
                        _loading = false;
                      });
                    }
                  },
                  text: 'Log In',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
