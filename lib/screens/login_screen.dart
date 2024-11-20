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
  bool isPasswordVisible = false;
  String emailError = '';
  String passwordError = '';
  String generalError = '';

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
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
        progressIndicator:
            const CircularProgressIndicator(color: Colors.lightBlueAccent),
        opacity: 0.0,
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Email TextField with Validation
                          TextField(
                            keyboardType: TextInputType.emailAddress,
                            textAlign: TextAlign.center,
                            onChanged: (value) {
                              email = value;
                              setState(() {
                                emailError = isValidEmail(value)
                                    ? ''
                                    : 'Invalid email format';
                              });
                            },
                            decoration: kLogInEmailDecoration.copyWith(
                              errorText: emailError.isEmpty ? null : emailError,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          // Password TextField with Visibility Toggle
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
                              suffixIcon: Tooltip(
                                message: isPasswordVisible
                                    ? 'Hide Password'
                                    : 'Show Password',
                                child: IconButton(
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
                          const SizedBox(height: 16.0),
                          // Log In Button
                          RoundedButton(
                            buttonColor: Colors.lightBlueAccent,
                            onPressed: () async {
                              if (email.isEmpty || !isValidEmail(email)) {
                                setState(() {
                                  emailError = 'Enter a valid email.';
                                });
                                return;
                              }

                              if (password.isEmpty) {
                                setState(() {
                                  passwordError = 'Please enter your password.';
                                });
                                return;
                              }

                              setState(() {
                                _loading = true;
                                generalError = '';
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
                                    Navigator.pushReplacementNamed(
                                        context, ChatScreen.id);
                                  } else {
                                    setState(() {
                                      generalError =
                                          'Email not verified. Please verify.';
                                    });
                                  }
                                }
                              } on FirebaseAuthException catch (e) {
                                setState(() {
                                  generalError = e.code == 'wrong-password'
                                      ? 'Incorrect password.'
                                      : e.code == 'user-not-found'
                                          ? 'No user found for this email.'
                                          : e.message ?? 'An error occurred.';
                                });
                              } finally {
                                setState(() {
                                  _loading = false;
                                });
                              }
                            },
                            text: 'Log In',
                          ),
                          // Forgot Password Button
                          TextButton(
                            onPressed: () async {
                              if (email.isEmpty || !isValidEmail(email)) {
                                setState(() {
                                  emailError =
                                      'Enter a valid email to reset password.';
                                });
                                return;
                              }

                              try {
                                await _auth.sendPasswordResetEmail(
                                    email: email);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Password reset email sent.')),
                                );
                              } catch (e) {
                                setState(() {
                                  generalError =
                                      'Error sending reset email: $e';
                                });
                              }
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.lightBlueAccent),
                            ),
                          ),
                          // Resend Verification Email
                          if (generalError.contains('not verified'))
                            TextButton(
                              onPressed: () async {
                                try {
                                  final user = _auth.currentUser;
                                  if (user != null) {
                                    await user.sendEmailVerification();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Verification email resent.')),
                                    );
                                  }
                                } catch (e) {
                                  setState(() {
                                    generalError = 'Error resending email: $e';
                                  });
                                }
                              },
                              child: const Text(
                                'Resend Verification Email',
                                style: TextStyle(color: Colors.lightBlueAccent),
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
      ),
    );
  }
}
