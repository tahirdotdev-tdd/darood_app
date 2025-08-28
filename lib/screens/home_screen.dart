// lib/screens/home_screen.dart

import 'dart:ui';
import 'package:darood_app/components/darood_count_card_glass.dart';
import 'package:darood_app/pages/counter_page.dart';
import 'package:darood_app/pages/profile_page.dart';
import 'package:darood_app/pages/settings_page.dart';
import 'package:darood_app/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:darood_app/main.dart'; // To access the global 'supabase' client

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _advancedDrawerController = AdvancedDrawerController();
  final GlobalKey _profileIconKey = GlobalKey();

  // THE FIX: The stream now correctly expects a List of results.
  Stream<List<Map<String, dynamic>>>? _profileStream;

  OverlayEntry? _overlayEntry;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeProfileStream();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );
  }

  // THE FIX: Removed the fragile ".map((maps) => maps.first)"
  void _initializeProfileStream() {
    final userId = supabase.auth.currentUser!.id;
    _profileStream = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId); // This correctly returns a Stream<List<Map>>
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  // ... (All other methods like _showDropdownMenu remain unchanged)
  void _showDropdownMenu() {
    final RenderBox renderBox = _profileIconKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _hideDropdownMenu,
          child: Stack(
            children: [
              Positioned(
                top: offset.dy + size.height + 5,
                right: 8,
                child: FadeTransition(
                  opacity: _fadeAnimation!,
                  child: ScaleTransition(
                    scale: _scaleAnimation!,
                    alignment: Alignment.topRight,
                    child: Material(
                      color: Colors.transparent,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 180,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMenuItem(
                                  context,
                                  icon: CupertinoIcons.person_fill,
                                  text: 'Edit Profile',
                                  onTap: () {
                                    _hideDropdownMenu();
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                                  },
                                ),
                                const Divider(height: 1),
                                _buildMenuItem(
                                  context,
                                  icon: CupertinoIcons.xmark_circle_fill,
                                  text: 'Close',
                                  color: CupertinoColors.destructiveRed,
                                  onTap: _hideDropdownMenu,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController!.forward();
  }

  void _hideDropdownMenu() {
    if (_overlayEntry != null) {
      _animationController!.reverse().then((value) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    }
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87), size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.poppins(fontSize: 15, color: color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdvancedDrawer(
      controller: _advancedDrawerController,
      backdrop: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withOpacity(0.5),
        ),
      ),
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      rtlOpening: false,
      drawer: SafeArea(
        child: Container(
          color: Colors.black87,
          child: ListTileTheme(
            textColor: Colors.white,
            iconColor: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(top: 24, bottom: 24),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.person_alt_circle,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.house_fill),
                  title: Text('Home', style: GoogleFonts.poppins(fontSize: 16)),
                  onTap: () {
                    _advancedDrawerController.hideDrawer();
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.profile_circled),
                  title: Text(
                    'Profile',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.map),
                  title: const Text('Map'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1F1),
        appBar: AppBar(
          actions: [
            GestureDetector(
              key: _profileIconKey,
              onLongPress: _showDropdownMenu,
              child: IconButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                },
                icon: const Icon(CupertinoIcons.person_alt_circle,color: Colors.black,),
              ),
            )
          ],
          title: Text(
            "Home",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFF1F1F1),
          leading: IconButton(
            onPressed: () {
              _advancedDrawerController.showDrawer();
            },
            icon: const Icon(CupertinoIcons.bars,color: Colors.black,),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen()));
                    },
                    child: Container(
                      margin: EdgeInsets.all(15),
                      alignment: Alignment.center,
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.map_fill,
                            size: 50,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Map",
                            style: GoogleFonts.poppins(fontSize: 20),
                          )
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                    },
                    child: Container(
                      margin: EdgeInsets.all(15),
                      alignment: Alignment.center,
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.settings,
                            size: 50,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Settings",
                            style: GoogleFonts.poppins(fontSize: 20),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CounterPage()));
                },
                child: Container(
                  margin: EdgeInsets.all(15),
                  alignment: Alignment.center,
                  height: 150,
                  width: 330,
                  decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.add_circled_solid,
                        size: 50,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Counter",
                        style: GoogleFonts.poppins(fontSize: 20),
                      )
                    ],
                  ),
                ),
              ),
              // THE FIX: The StreamBuilder now handles a List and checks it safely.
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _profileStream,
                builder: (context, snapshot) {
                  // Safely handle loading and empty states
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return DaroodCountCardGlass(daroodCount: 0);
                  }

                  // If we have data, get the count from the first item in the list
                  final profileData = snapshot.data!.first;
                  final daroodCount = profileData['darood_count'] ?? 0;
                  return DaroodCountCardGlass(daroodCount: daroodCount);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}