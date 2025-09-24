import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

final supabase = Supabase.instance.client;

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Re-initialize Supabase in background isolate
    await Supabase.initialize(
      url: 'https://vdlzkjljamnrpdqtistw.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkbHpramxqYW1ucnBkcXRpc3R3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYwOTQ4MDIsImV4cCI6MjA3MTY3MDgwMn0.dymWhgxEDLPuNO9atq5b7gQvQrZQiZxO8gejTsbIZ6I',
    );
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return Future.value(true);
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            return Future.value(true);
          }
        }
        if (permission == LocationPermission.deniedForever) {
          return Future.value(true);
        }

        final pos = await Geolocator.getCurrentPosition();
        await supabase
            .from('profiles')
            .update({'location': 'POINT(${pos.longitude} ${pos.latitude})'})
            .eq('id', user.id);

        print('✅ Background location updated in Supabase.');
      } catch (e) {
        print('❌ Error updating location in background: $e');
      }
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vdlzkjljamnrpdqtistw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkbHpramxqYW1ucnBkcXRpc3R3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYwOTQ4MDIsImV4cCI6MjA3MTY3MDgwMn0.dymWhgxEDLPuNO9atq5b7gQvQrZQiZxO8gejTsbIZ6I',
  );
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Register periodic background location update every 15min (Android/iOS minimum)
  await Workmanager().registerPeriodicTask(
    "backgroundLocationTask",
    "updateLocationTask",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(const MyApp());
}

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
