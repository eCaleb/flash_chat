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
  String email = '';
  String password = '';
  bool _loading = false;
  String emailError = '';
  bool isPasswordVisible = false;
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
        blur: BorderSide.strokeAlignCenter,
        color: Colors.lightBlueAccent,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                flex: keyboardVisible ? 2 : 3,
                child: Hero(
                  tag: 'logo',
                  child: Image.asset('assets/images/logo.png'),
                ),
              ),
              const SizedBox(height: 10.0),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SingleChildScrollView(
                    reverse: true,
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
                          obscureText: !isPasswordVisible,
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            password = value;
                            setState(() {
                              passwordError = '';
                            });
                          },
                          decoration: kLogInPasswordDecoration.copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),
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
                              final userCredential =
                                  await _auth.signInWithEmailAndPassword(
                                email: email,
                                password: password,
                              );

                              final user = userCredential.user;
                              if (user != null) {
                                if (user.emailVerified) {
                                  // Email is verified, proceed to chat screen
                                  Navigator.pushReplacementNamed(
                                      context, ChatScreen.id);
                                } else {
                                  // Email is not verified
                                  setState(() {
                                    generalError =
                                        'Email is not verified. Please verify your email.';
                                  });
                                }
                              }
                            } on FirebaseAuthException catch (e) {
                              setState(() {
                                generalError =
                                    e.message ?? 'An error occurred.';
                              });
                            } catch (e) {
                              setState(() {
                                generalError =
                                    'An unexpected error occurred: $e';
                              });
                            } finally {
                              setState(() {
                                _loading = false;
                              });
                            }
                          },
                          text: 'Log In',
                        ),
                        const SizedBox(height: 16.0),
                        if (generalError.contains('not verified'))
                          TextButton(
                            onPressed: () async {
                              try {
                                final user = _auth.currentUser;
                                if (user != null) {
                                  await user.sendEmailVerification();
                                  setState(() {
                                    generalError =
                                        'Verification email sent. Please check your inbox.';
                                  });
                                }
                              } catch (e) {
                                setState(() {
                                  generalError =
                                      'Error sending verification email: $e';
                                });
                              }
                            },
                            child: const Text(
                              'Resend Verification Email',
                              style: TextStyle(color: Colors.blueAccent),
                            ),
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
