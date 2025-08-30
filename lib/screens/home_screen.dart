// lib/screens/home_screen.dart

import 'dart:ui';
import 'package:darood_app/components/darood_count_card_glass.dart';
import 'package:darood_app/pages/counter_page.dart';
import 'package:darood_app/pages/profile_page.dart';
import 'package:darood_app/pages/settings_page.dart';
import 'package:darood_app/screens/map_screen.dart';
import 'package:darood_app/styles/colors/colors.dart';
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

  // The stream will handle a List of results, which is safer.
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

  void _showDropdownMenu() {
    final RenderBox renderBox =
        _profileIconKey.currentContext!.findRenderObject() as RenderBox;
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
                              color: CupertinoColors.systemGrey6.withOpacity(
                                0.8,
                              ),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProfilePage(),
                                      ),
                                    );
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

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  color ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color:
                    color ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87),
              ),
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
        child: Container(color: Colors.black.withOpacity(0.5)),
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
            iconColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _profileStream,
                    builder: (context, snapshot) {
                      // Safely get the avatar URL and username from the stream's data
                      final hasData =
                          snapshot.hasData && snapshot.data!.isNotEmpty;
                      final avatarUrl = hasData
                          ? snapshot.data!.first['avatar_url'] as String?
                          : null;
                      final username = hasData
                          ? snapshot.data!.first['username'] as String?
                          : null;

                      return Column(
                        children: [
                          // This container is for the avatar
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(
                              top: 24,
                              bottom: 12,
                            ), // Adjusted bottom margin
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
                              // Use NetworkImage if URL exists, otherwise it remains transparent
                              image: (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            // Show an icon only if there is NO image
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? const Icon(
                                    CupertinoIcons.person_alt_circle,
                                    size: 60,
                                    color: Colors.white70,
                                  )
                                : null,
                          ),
                          // This Text widget displays the username
                          Text(
                            username ??
                                'User', // Display username, or 'User' as a fallback
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          // Add some space before the list tiles start
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.house_fill,
                    color: Colors.orange,
                  ),
                  title: Text('Home', style: GoogleFonts.poppins(fontSize: 16)),
                  onTap: () {
                    _advancedDrawerController.hideDrawer();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.profile_circled,
                    color: Colors.orange,
                  ),
                  title: Text(
                    'Profile',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.map, color: Colors.orange),
                  title: Text('Map', style: GoogleFonts.poppins(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.settings,
                    color: Colors.orange,
                  ),
                  title: Text(
                    'Settings',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
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
        backgroundColor: mainBcg,
        appBar: AppBar(
          actions: [
            // The AppBar's avatar is also powered by the same stream
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _profileStream,
              builder: (context, snapshot) {
                final avatarUrl =
                    (snapshot.hasData && snapshot.data!.isNotEmpty)
                    ? snapshot.data!.first['avatar_url'] as String?
                    : null;

                return GestureDetector(
                  key: _profileIconKey,
                  onLongPress: _showDropdownMenu,
                  child: IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                    icon: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(avatarUrl),
                          )
                        : const Icon(
                            CupertinoIcons.person_alt_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                );
              },
            ),
          ],
          title: Text(
            "Home",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: mainBcg,
          leading: IconButton(
            onPressed: () {
              _advancedDrawerController.showDrawer();
            },
            icon: const Icon(CupertinoIcons.bars, color: Colors.white),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.all(15),
                      alignment: Alignment.center,
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: tileBcg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.map_fill,
                            size: 50,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Map",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.all(15),
                      alignment: Alignment.center,
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: tileBcg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.settings,
                            size: 50,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Settings",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CounterPage(),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.all(15),
                  alignment: Alignment.center,
                  height: 150,
                  width: 330,
                  decoration: BoxDecoration(
                    color: tileBcg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.add_circled_solid,
                        size: 50,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Counter",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _profileStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return DaroodCountCardGlass(daroodCount: 0);
                  }

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
