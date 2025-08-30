import 'package:darood_app/styles/colors/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:darood_app/main.dart'; // To access the global 'supabase' client

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  Stream<List<Map<String, dynamic>>>? _profileStream;
  bool _isPressed = false;
  bool _isResetPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeProfileStream();
  }

  void _initializeProfileStream() {
    final userId = supabase.auth.currentUser!.id;
    _profileStream = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId);
  }

  void _incrementCounter() async {
    await supabase.rpc(
      'increment_darood_count',
      params: {'user_id': supabase.auth.currentUser!.id, 'increment_value': 1},
    );
  }

  void _resetCounter() async {
    await supabase.rpc(
      'reset_darood_count',
      params: {'user_id': supabase.auth.currentUser!.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Counter",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: mainBcg,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
      ),
      backgroundColor: mainBcg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _profileStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    '0',
                    style: GoogleFonts.poppins(
                      fontSize: 180,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.orange.withOpacity(0.8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  );
                }

                final profileData = snapshot.data!.first;
                final count = profileData['darood_count'] ?? 0;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                  child: Text(
                    '$count',
                    key: ValueKey<int>(count),
                    style: GoogleFonts.poppins(
                      fontSize: 180,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.orange.withOpacity(0.8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) {
                    setState(() => _isPressed = false);
                    _incrementCounter();
                  },
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: AnimatedScale(
                    scale: _isPressed ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tileBcg,
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.1),
                            spreadRadius: 5,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '+1',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.orange.shade800,
                            fontSize: 74,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                GestureDetector(
                  onTapDown: (_) => setState(() => _isResetPressed = true),
                  onTapUp: (_) {
                    setState(() => _isResetPressed = false);
                    _resetCounter();
                  },
                  onTapCancel: () => setState(() => _isResetPressed = false),
                  child: AnimatedScale(
                    scale: _isResetPressed ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red[100],
                        border: Border.all(
                          color: Colors.redAccent.shade100,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.08),
                            spreadRadius: 4,
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.refresh,
                          color: Colors.red[700],
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
