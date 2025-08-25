import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/login_screen.dart';

class MainSignUpButton extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const MainSignUpButton({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.usernameController,
  });

  @override
  State<MainSignUpButton> createState() => _MainSignUpButtonState();
}

class _MainSignUpButtonState extends State<MainSignUpButton> {
  bool isLoading = false;

  Future<void> _signUp() async {
    setState(() => isLoading = true);

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: widget.emailController.text.trim(),
        password: widget.passwordController.text.trim(),
        data: {
          'username': widget.usernameController.text
              .trim(), // 👈 store username in metadata
        },
      );

      if (res.user != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Signup successful!")));

        // Navigate to login and pass email & password
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              email: widget.emailController.text.trim(),
              password: widget.passwordController.text.trim(),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unexpected error occurred")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : _signUp,
      child: Container(
        alignment: Alignment.center,
        width: 300,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(30),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.black)
            : Text(
                "Sign Up",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
