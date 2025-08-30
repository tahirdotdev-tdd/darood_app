import 'package:darood_app/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vdlzkjljamnrpdqtistw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkbHpramxqYW1ucnBkcXRpc3R3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYwOTQ4MDIsImV4cCI6MjA3MTY3MDgwMn0.dymWhgxEDLPuNO9atq5b7gQvQrZQiZxO8gejTsbIZ6I',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Darood App',
      home: const SplashScreen(),
    );
  }
}
