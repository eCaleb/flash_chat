import 'package:flash_chat/constants.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:flash_chat/screens/components/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = 'registration_screen';
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  String email = '';
  String password = '';
  bool _loading = false;
  String emailError = '';
  String passwordError = '';
  String generalError = '';

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  bool isValidPassword(String password) {
    return password.length >= 6 &&
        !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                flex: keyboardVisible ? 2 : 3, // Shrink the Hero widget when keyboard is visible
                child: Hero(
                  tag: 'logo',
                  child: Image.asset('assets/images/logo.png'),
                ),
              ),
              const SizedBox(height: 10.0), // Controlled spacing between Hero and form
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SingleChildScrollView(
                    reverse: true, // Ensure the view scrolls when the keyboard appears
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextField(
                          keyboardType: TextInputType.emailAddress,
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            email = value;
                            setState(() {
                              emailError = '';
                            });
                          },
                          decoration: kRegisterEmailDecoration,
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
                          decoration: kRegisterPasswordDecoration,
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
                          buttonColor: Colors.blueAccent,
                          onPressed: () async {
                            setState(() {
                              emailError = '';
                              passwordError = '';
                              generalError = '';
                            });

                            if (email.isEmpty) {
                              setState(() {
                                emailError = 'Please enter your email.';
                              });
                              return;
                            }

                            if (!isValidEmail(email)) {
                              setState(() {
                                emailError = 'Please enter a valid email.';
                              });
                              return;
                            }

                            if (password.isEmpty) {
                              setState(() {
                                passwordError = 'Please enter your password.';
                              });
                              return;
                            }

                            if (!isValidPassword(password)) {
                              setState(() {
                                passwordError =
                                    'Password must be 6+ characters without special symbols.';
                              });
                              return;
                            }

                            setState(() {
                              _loading = true;
                            });

                            try {
                              final newUser = await _auth.createUserWithEmailAndPassword(
                                email: email,
                                password: password,
                              );
                              if (newUser != null) {
                                Navigator.pushNamed(context, ChatScreen.id);
                              }
                            } catch (e) {
                              setState(() {
                                generalError = e.toString();
                              });
                            } finally {
                              setState(() {
                                _loading = false;
                              });
                            }
                          },
                          text: 'Register',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
