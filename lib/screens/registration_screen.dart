import 'package:flash_chat/constants.dart';
import 'package:flash_chat/widgets/rounded_button.dart';
import 'package:flash_chat/screens/login_screen.dart';
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
  bool isPasswordVisible = false;
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
        progressIndicator: const CircularProgressIndicator(color: Colors.blueAccent),
        opacity: 0.0,
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Flexible(
                  flex: 3,
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
                          // Email TextField with validation
                          TextField(
                            keyboardType: TextInputType.emailAddress,
                            textAlign: TextAlign.center,
                            onChanged: (value) {
                              email = value;
                              setState(() {
                                emailError = isValidEmail(value) ? '' : 'Invalid email format';
                              });
                            },
                            decoration: kRegisterEmailDecoration.copyWith(
                              errorText: emailError.isEmpty ? null : emailError,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          // Password TextField with toggle and validation
                          TextField(
                            obscureText: !isPasswordVisible,
                            textAlign: TextAlign.center,
                            onChanged: (value) {
                              password = value;
                              setState(() {
                                passwordError = isValidPassword(value)
                                    ? ''
                                    : 'Password must be 6+ characters and not contain special symbols.';
                              });
                            },
                            decoration: kRegisterPasswordDecoration.copyWith(
                              suffixIcon: Tooltip(
                                message: isPasswordVisible ? 'Hide Password' : 'Show Password',
                                child: IconButton(
                                  icon: Icon(
                                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isPasswordVisible = !isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              errorText: passwordError.isEmpty ? null : passwordError,
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          if (generalError.isNotEmpty)
                            Text(
                              generalError,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 16.0),
                          // Register Button
                          RoundedButton(
                            buttonColor: Colors.blueAccent,
                            onPressed: () async {
                              if (email.isEmpty || !isValidEmail(email)) {
                                setState(() {
                                  emailError = 'Enter a valid email.';
                                });
                                return;
                              }
                              if (password.isEmpty || !isValidPassword(password)) {
                                setState(() {
                                  passwordError =
                                      'Password must be 6+ characters and not contain special symbols.';
                                });
                                return;
                              }
            
                              setState(() {
                                _loading = true;
                                generalError = '';
                              });
            
                              try {
                                final newUser =
                                    await _auth.createUserWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );
                                // Send email verification
                                await newUser.user!.sendEmailVerification();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Verification email sent.')),
                                );
            
                                // Redirect to login
                                await Future.delayed(const Duration(seconds: 2));
                                Navigator.pushReplacementNamed(context, LoginScreen.id);
                              } on FirebaseAuthException catch (e) {
                                setState(() {
                                  generalError =
                                      e.code == 'email-already-in-use'
                                          ? 'This email is already registered.'
                                          : e.message ?? 'An error occurred.';
                                });
                              } catch (e) {
                                setState(() {
                                  generalError = 'An unexpected error occurred: $e';
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
      ),
    );
  }
}
