import 'package:chat_app/pages/home_page.dart';
import 'package:chat_app/services/auth/signIn_or_signUp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthenticstionGate extends StatelessWidget {
  const AuthenticstionGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const HomePage();
          } else {
            return SignInOrSignUp();
          }
        },
      ),
    );
  }
}
