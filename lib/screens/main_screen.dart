import 'package:darood_app/components/anon_button.dart';
import 'package:darood_app/components/primary_button.dart';
import 'package:darood_app/components/secondary_button.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/bcg.jpg'),
                fit: BoxFit.cover, // better than fitHeight for full coverage
              ),
            ),
          ),

          // Black overlay
          Container(
            color: Colors.black.withOpacity(0.7), // adjust opacity as needed
          ),

          // Foreground content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome to\nDarood App",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade300, // lighter shade for contrast
                  ),
                ),
                SizedBox(height: 60,),
                PrimaryButton(),
                SizedBox(height: 10,),
                SecondaryButton(text: "Login",),
                SizedBox(height: 10,),
                AnonButton()
              ],
            ),
          ),
        ],
      ),
    );
  }
}
