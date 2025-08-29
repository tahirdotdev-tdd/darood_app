import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:darood_app/main.dart';

// AppUser model now includes the username
class AppUser {
  final String id;
  final String? username;
  final String? avatarUrl;
  final int daroodCount;
  final LatLng location;

  AppUser({
    required this.id,
    this.username,
    this.avatarUrl,
    required this.daroodCount,
    required this.location,
  });
}

class CustomTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return NetworkImage(
      url,
      headers: {
        'User-Agent': 'com.darood_app.app',
      },
    );
  }
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
  Stream<List<Map<String, dynamic>>>? _currentUserStream;
  LatLng? _currentPosition;

  LatLng? _searchedPosition;
  late final AnimationController _animationController;

  final List<Map<String, String>> _mapStyles = [
    {'name': 'Streets', 'url': 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=mpCE8zqBYILJn993DJrN'},
    {'name': 'Basic', 'url': 'https://api.maptiler.com/maps/basic/{z}/{x}/{y}.png?key=mpCE8zqBYILJn993DJrN'},
    {'name': 'Bright', 'url': 'https://api.maptiler.com/maps/bright/{z}/{x}/{y}.png?key=mpCE8zqBYILJn993DJrN'},
    {'name': 'Pastel', 'url': 'https://api.maptiler.com/maps/pastel/{z}/{x}/{y}.png?key=mpCE8zqBYILJn993DJrN'},
    {'name': 'Satellite', 'url': 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=mpCE8zqBYILJn993DJrN'},
    {'name': 'Hybrid', 'url': 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=mpCE8zqBYILJn993DJrN'},
    {'name': 'Topo', 'url': 'https://api.maptiler.com/maps/topo/{z}/{x}/{y}.png?key=mpCE8zqBYILJn993DJrN'},
    {'name': 'Toner', 'url': 'https://api.maptiler.com/maps/toner/{z}/{x}/{y}.png?key=mpCE8zqBYILJn993DJrN'},
    {'name': 'Dark', 'url': 'https://api.maptiler.com/maps/darkmatter/{z}/{x}/{y}.png?key=mpCE8zqBYILJn993DJrN'},
    {'name': 'Winter', 'url': 'https://api.maptiler.com/maps/winter/{z}/{x}/{y}.png?key=mpCE8zqBYILJn993DJrN'},
  ];
  int _selectedMapStyleIndex = 0;

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
        .from('profiles_with_geojson_location')
        .stream(primaryKey: ['id'])
        .map((listOfMaps) {
      final List<AppUser> users = [];
      for (final map in listOfMaps) {
        final geoJsonString = map['location_geojson'] as String?;
        if (geoJsonString != null) {
          try {
            final geoJson = json.decode(geoJsonString);
            final coordinates = geoJson['coordinates'] as List;
            final lon = coordinates[0] as double;
            final lat = coordinates[1] as double;

            users.add(AppUser(
              id: map['id'],
              username: map['username'],
              avatarUrl: map['avatar_url'],
              daroodCount: map['darood_count'] ?? 0,
              location: LatLng(lat, lon),
            ));
          } catch(e) {
            print('Error parsing GeoJSON: $e');
          }
        }
      }
      return users;
    });

    final userId = supabase.auth.currentUser!.id;
    _currentUserStream = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId);
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
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _currentUserStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

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

  Future<String?> _getCityFromLatLng(LatLng location) async {
    // Using OpenStreetMap Nominatim reverse geocoding.
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json&zoom=10&addressdetails=1',
    );
    try {
      final response = await http.get(url, headers: {'User-Agent': 'com.darood_app.app'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};
        return address['city'] ?? address['town'] ?? address['village'] ?? address['state'] ?? null;
      }
    } catch (e) {
      // ignore error, just show nothing
    }
    return null;
  }

  void _showUserDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (context) {
        final isCurrentUser = user.id == supabase.auth.currentUser!.id;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<String?>(
              future: _getCityFromLatLng(user.location),
              builder: (context, snapshot) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                          ? Icon(Icons.person, size: 44, color: Colors.blueGrey)
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.username ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (snapshot.hasData && snapshot.data != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_city, color: Colors.teal, size: 19),
                            const SizedBox(width: 5),
                            Text(
                              snapshot.data!,
                              style: TextStyle(fontSize: 16, color: Colors.teal[800]),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite, color: Colors.pink, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Darood Count: ',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        Text(
                          user.daroodCount.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: isCurrentUser ? Colors.blue : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text("Close"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[50],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Marker _buildUserMarker(AppUser user, {double offsetX = 0.0}) {
    final isCurrentUser = user.id == supabase.auth.currentUser!.id;

    return Marker(
      width: 150,
      height: 80,
      point: user.location,
      child: GestureDetector(
        onTap: () => _showUserDialog(user),
        child: Transform.translate(
          offset: Offset(offsetX, 0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  border: isCurrentUser ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.username ?? 'User',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
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
                            fontSize: 14,
                            color: isCurrentUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
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
        ),
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

              final List<Marker> processedMarkers = [];
              final Map<String, List<AppUser>> usersByLocation = {};

              for (final user in users) {
                final locationKey = '${user.location.latitude.toStringAsFixed(5)},${user.location.longitude.toStringAsFixed(5)}';
                usersByLocation.putIfAbsent(locationKey, () => []).add(user);
              }

              usersByLocation.forEach((key, group) {
                if (group.length > 1) {
                  const double offsetStep = 40.0;
                  double startOffset = - (group.length - 1) * offsetStep / 2;

                  for (int i = 0; i < group.length; i++) {
                    final user = group[i];
                    final offsetX = startOffset + (i * offsetStep);
                    processedMarkers.add(_buildUserMarker(user, offsetX: offsetX));
                  }
                } else {
                  processedMarkers.add(_buildUserMarker(group.first));
                }
              });

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition!,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _mapStyles[_selectedMapStyleIndex]['url']!,
                    userAgentPackageName: 'com.darood_app.app',
                  ),
                  MarkerLayer(markers: processedMarkers),
                  if (_searchedPosition != null)
                    MarkerLayer(markers: [_buildSearchedLocationMarker()]),
                ],
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 15,
            left: 15,
            right: 15,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMapStyleIndex,
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMapStyleIndex = value;
                          });
                        }
                      },
                      items: List.generate(_mapStyles.length, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text(_mapStyles[index]['name']!),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
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