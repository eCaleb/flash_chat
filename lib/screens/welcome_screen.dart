import 'package:flutter/material.dart';
import 'package:flash_chat/screens/login_screen.dart';
import 'package:flash_chat/screens/registration_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/rounded_button.dart';
import '../widgets/language_selector.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  static const String id = 'welcome_screen';

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation animationColor;
  late Animation animationSize;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    animationColor = ColorTween(begin: Colors.blueGrey, end: Colors.white)
        .animate(controller);
    animationSize = Tween(begin: 0.0, end: 80.0).animate(controller);

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
    final screenSize = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: animationColor.value,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double fontSize = screenSize.width * 0.10;
                    fontSize = fontSize.clamp(35.0, 60.0);
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'logo',
                          child: SizedBox(
                            height: animationSize.value,
                            child: Image.asset('assets/images/logo.png'),
                          ),
                        ),
                        SizedBox(width: 15),
                        Flexible(
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                l10n.appTitle,
                                textStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                speed: const Duration(milliseconds: 200),
                              ),
                            ],
                            repeatForever: false,
                            totalRepeatCount: 1,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 48.0),
              RoundedButton(
                buttonColor: Colors.lightBlueAccent,
                onPressed: () {
                  Navigator.pushNamed(context, LoginScreen.id);
                },
                text: l10n.loginButton,
              ),
              RoundedButton(
                buttonColor: Colors.blueAccent,
                onPressed: () {
                  Navigator.pushNamed(context, RegistrationScreen.id);
                },
                text: l10n.registerButton,
              ),
              const SizedBox(height: 24.0),
              // Language Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.selectLanguage,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Consumer<LocaleProvider>(
                    builder: (context, localeProvider, child) {
                      return Theme(
                        // Custom theme for the dropdown to match your app's style
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.white,
                          buttonTheme: ButtonTheme.of(context).copyWith(
                            alignedDropdown: true,
                          ),
                        ),
                        child: LanguageSelector(
                          currentLocale: localeProvider.locale,
                          onLocaleChange: (newLocale) {
                            localeProvider.setLocale(newLocale);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}