import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ Replace with your actual HomeScreen widget import
import '../screens/home_screen.dart';

class MainLogInButton extends StatefulWidget {
  final String text;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const MainLogInButton({
    super.key,
    required this.text,
    required this.emailController,
    required this.passwordController,
  });

  @override
  State<MainLogInButton> createState() => _MainLogInButtonState();
}

class _MainLogInButtonState extends State<MainLogInButton> {
  bool isLoading = false;

  Future<void> _login() async {
    setState(() => isLoading = true);

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: widget.emailController.text.trim(),
        password: widget.passwordController.text.trim(),
      );

      if (res.user != null) {
        // ✅ Login successful
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login successful!")));

        // ✅ Navigate to HomeScreen & remove login screen from stack
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
      onTap: isLoading ? null : _login,
      child: Container(
        alignment: Alignment.center,
        width: 300,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(width: 2, color: Colors.white),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
