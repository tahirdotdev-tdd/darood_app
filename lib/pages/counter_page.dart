// lib/screens/counter_page.dart

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
  // THE FIX: The stream now correctly expects a List of results.
  Stream<List<Map<String, dynamic>>>? _profileStream;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeProfileStream();
  }

  // THE FIX: Removed the fragile ".map((maps) => maps.first)"
  void _initializeProfileStream() {
    final userId = supabase.auth.currentUser!.id;
    _profileStream = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId); // This correctly returns a Stream<List<Map>>
  }

  void _incrementCounter() async {
    await supabase.rpc('increment_darood_count', params: {
      'user_id': supabase.auth.currentUser!.id,
      'increment_value': 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Counter",
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
            // THE FIX: The StreamBuilder now handles a List and checks it safely.
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _profileStream,
              builder: (context, snapshot) {
                // Safely handle loading and empty states
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    '0', // Show 0 if there's no data yet or the list is empty
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

                // If we have data, get the count from the first item in the list
                final profileData = snapshot.data!.first;
                final count = profileData['darood_count'] ?? 0;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
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
                  width: 260,
                  height: 260,
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
          ],
        ),
      ),
    );
  }
}