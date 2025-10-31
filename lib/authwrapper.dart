import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:klydra/login.dart';
import 'package:klydra/nav/navbar.dart';

// Use this as your home widget in main.dart
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2196F3),
              ),
            ),
          );
        }
        
        // If user is logged in, show main navigation
        if (snapshot.hasData) {
          return const MainNavigationPage();
        }
        
        // If user is not logged in, show login page
        return const LoginPage();
      },
    );
  }
}