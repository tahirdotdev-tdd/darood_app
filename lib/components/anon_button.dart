import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnonButton extends StatefulWidget {
  const AnonButton({super.key});

  @override
  State<AnonButton> createState() => _AnonButtonState();
}

class _AnonButtonState extends State<AnonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // smooth animation
    )..repeat(); // repeat forever

    animation = Tween<double>(begin: 0, end: 360).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.black,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag indicator
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Username field
                  TextField(
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter your username",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    alignment: Alignment.center,
                    height: 60,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "Continue",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },

      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Container(
            alignment: Alignment.center,
            width: 300,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: _generateGradientColors(animation.value),
                stops: _generateGradientStops(),
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(-4, 4),
                  color: Colors.black38,
                ),
              ],
              borderRadius: BorderRadius.circular(30),
              border: Border.all(width: 2, color: Colors.white),
            ),
            child: Text(
              "Go Anonymous",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}

List<Color> _generateGradientColors(double offset) {
  List<Color> colors = [];
  const int divisions = 10;
  for (int i = 0; i < divisions; i++) {
    double hue = (360 / divisions) * i;
    hue += offset;
    if (hue > 360) hue -= 360;
    final Color color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
    colors.add(color);
  }
  colors.add(colors[0]); // smooth loop
  return colors;
}

List<double> _generateGradientStops() {
  const int divisions = 10;
  return List.generate(divisions + 1, (i) => i / divisions);
}
