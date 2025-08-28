// lib/screens/map_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:darood_app/main.dart';

class AppUser {
  final String id;
  final String? avatarUrl;
  final int daroodCount;
  final LatLng location;

  AppUser({
    required this.id,
    this.avatarUrl,
    required this.daroodCount,
    required this.location,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<Position>? _positionStream;
  Stream<List<AppUser>>? _usersStream;

  // THE FIX: The stream for the current user is now robust and expects a List.
  Stream<List<Map<String, dynamic>>>? _currentUserStream;
  LatLng? _currentPosition;

  LatLng? _searchedPosition;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeMap();
  }

  void _initializeMap() {
    _getInitialLocationAndStartStream();

    _usersStream = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((listOfMaps) {
      final List<AppUser> users = [];
      for (final map in listOfMaps) {
        final locationString = map['location'] as String?;
        if (locationString != null) {
          final parts = locationString.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
          if (parts.length == 2) {
            final lon = double.tryParse(parts[0]);
            final lat = double.tryParse(parts[1]);
            if (lat != null && lon != null) {
              users.add(AppUser(
                id: map['id'],
                avatarUrl: map['avatar_url'],
                daroodCount: map['darood_count'] ?? 0,
                location: LatLng(lat, lon),
              ));
            }
          }
        }
      }
      return users;
    });

    // THE FIX: Removed the fragile ".map((maps) => maps.first)"
    final userId = supabase.auth.currentUser!.id;
    _currentUserStream = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId); // This correctly returns a Stream<List<Map>>
  }

  Future<void> _getInitialLocationAndStartStream() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentPosition!, 15.0);
        await _updateLocationInSupabase(position);
      }
    } catch (e) {
      // Handle errors
    }

    _startLocationStream();
  }

  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _updateLocationInSupabase(position);
      }
    });
  }

  Future<void> _updateLocationInSupabase(Position position) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('profiles').update({
      'location': 'POINT(${position.longitude} ${position.latitude})'
    }).eq('id', userId);
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _searchedPosition = null;
    });

    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');

    try {
      final response = await http.get(url, headers: {'User-Agent': 'com.darood_app.app'});
      if (response.statusCode == 200) {
        final results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]["lat"]);
          final lon = double.parse(results[0]["lon"]);
          final searchedLatLng = LatLng(lat, lon);

          setState(() {
            _searchedPosition = searchedLatLng;
          });
          _mapController.move(searchedLatLng, 14.0);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not found.')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error searching: $e')));
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showCounterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // THE FIX: This StreamBuilder now safely handles a List.
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _currentUserStream,
          builder: (context, snapshot) {
            // Safely handle loading and empty states
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Safely get the count from the first item in the list
            final profileData = snapshot.data!.first;
            final count = profileData['darood_count'] ?? 0;

            return Container(
              height: 250,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Your Darood Count: $count", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(40)),
                    onPressed: () async {
                      await supabase.rpc('increment_darood_count', params: {
                        'user_id': supabase.auth.currentUser!.id,
                        'increment_value': 1,
                      });
                    },
                    child: const Text("+1", style: TextStyle(fontSize: 24)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Marker _buildUserMarker(AppUser user) {
    final isCurrentUser = user.id == supabase.auth.currentUser!.id;

    return Marker(
      width: 120,
      height: 60,
      point: user.location,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              border: isCurrentUser ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: isCurrentUser ? 14 : 12,
                  backgroundColor: isCurrentUser ? Colors.white : Colors.grey.shade200,
                  backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                      ? Icon(Icons.person, size: isCurrentUser ? 18 : 16, color: isCurrentUser ? Colors.blue : Colors.grey)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  user.daroodCount.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          ClipPath(
            clipper: TriangleClipper(),
            child: Container(
              color: isCurrentUser ? Colors.blue : Colors.white,
              height: 8,
              width: 16,
            ),
          )
        ],
      ),
    );
  }

  Marker _buildSearchedLocationMarker() {
    return Marker(
      width: 80,
      height: 80,
      point: _searchedPosition!,
      child: FadeTransition(
        opacity: _animationController.drive(Tween<double>(begin: 0.5, end: 1.0)),
        child: const Icon(
          Icons.location_pin,
          color: Colors.purple,
          size: 60,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<AppUser>>(
            stream: _usersStream,
            builder: (context, snapshot) {
              if (_currentPosition == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = snapshot.data ?? [];

              // THE FIX: Added a check for empty user data to provide feedback.
              if (snapshot.connectionState == ConnectionState.active && users.isEmpty) {
                return Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition!,
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.darood_app.app',
                        ),
                      ],
                    ),
                    const Center(
                      child: Text(
                        "Searching for users...\nMake sure your location is updated.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, backgroundColor: Colors.white54),
                      ),
                    ),
                  ],
                );
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition!,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.darood_app.app',
                  ),
                  // Separated layers for clarity
                  if (_searchedPosition != null)
                    MarkerLayer(markers: [_buildSearchedLocationMarker()]),

                  MarkerLayer(
                    markers: users.map(_buildUserMarker).toList(),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 15,
            left: 15,
            right: 15,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  ),
                ),
                onSubmitted: (_) => _searchLocation(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "center_location_button",
            mini: true,
            onPressed: () {
              if (_currentPosition != null) {
                setState(() {
                  _searchedPosition = null;
                });
                _mapController.move(_currentPosition!, 15.0);
              }
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "increment_button",
            onPressed: _showCounterBottomSheet,
            label: const Text("Increment Count"),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<ui.Path> oldClipper) => false;
}