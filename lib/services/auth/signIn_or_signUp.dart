import 'package:chat_app/pages/signin_page.dart';
import 'package:chat_app/pages/signup_page.dart';
import 'package:flutter/material.dart';

class SignInOrSignUp extends StatefulWidget {
  const SignInOrSignUp({super.key});

  @override
  State<SignInOrSignUp> createState() => _SignInOrSignUpState();
}

class _SignInOrSignUpState extends State<SignInOrSignUp> {
  bool showSignInPage = true;

  void togglePages() {
    setState(() {
      showSignInPage = !showSignInPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showSignInPage) {
      return SignInPage(onTap: togglePages);
    } else {
      return SignUpPage(onTap: togglePages);
    }
  }
}
