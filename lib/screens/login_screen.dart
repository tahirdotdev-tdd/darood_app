// lib/screens/login_screen.dart

import 'package:darood_app/components/main_log_in_button.dart';
import 'package:darood_app/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? email;
  final String? password;

  const LoginScreen({super.key, this.email, this.password});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showPassword = false;

  // ===== THE FIX - PART 1: Declare the controllers here =====
  // We declare the controllers as final instance variables of the State class.
  // "late final" means they will be initialized once and will not change.
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  // ===== THE FIX - PART 2: Initialize controllers in initState =====
  // initState is called only ONCE when the widget is first created.
  // This is the perfect place to create controllers to preserve their state.
  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.email ?? '');
    passwordController = TextEditingController(text: widget.password ?? '');
  }

  // ===== THE FIX - PART 3: Dispose of controllers to prevent memory leaks =====
  // dispose() is called when the widget is permanently removed from the screen.
  // It's crucial to clean up controllers here.
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ===== THE FIX - PART 4: Remove controller creation from the build method =====
    // The controllers are now part of the widget's state and are reused on every rebuild.

    const Color accentColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1C),
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          },
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
        ),
      ),
      backgroundColor: Color(0xFF1C1C1C),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Log in to your account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Email Text Field (no changes here)
                  TextField(
                    controller: emailController,
                    cursorColor: Colors.orange,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      labelText: 'Email',
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: accentColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.black,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 20.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Text Field (no changes here)
                  TextField(
                    controller: passwordController,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    cursorColor: Colors.orange,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: accentColor,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.black,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 20.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Log In Button (no changes here)
                  MainLogInButton(
                    text: "Login",
                    emailController: emailController,
                    passwordController: passwordController,
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Redirect (no changes here)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
