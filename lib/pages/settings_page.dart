import 'package:darood_app/pages/profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart'; // Ensure this path is correct for your project

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  final Color primaryOrange = Colors.orange; // Define color for reuse

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error signing out: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF008080),
      appBar: AppBar(
        backgroundColor: const Color(0xFF008080),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
        ),
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Account"),
            const SizedBox(height: 10),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: CupertinoIcons.person_fill,
                title: "Profile",
                onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));},
              ),
            ]),
            const SizedBox(height: 20),
            _buildSectionHeader("Preferences"),
            const SizedBox(height: 10),
            _buildSettingsCard([
              SwitchListTile(
                secondary: Icon(CupertinoIcons.moon_fill, color: primaryOrange),
                title: const Text("Dark Mode"),
                value: isDarkMode,
                onChanged: (val) {
                  setState(() => isDarkMode = val);
                },
                activeColor: primaryOrange,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildSettingsTile(
                icon: CupertinoIcons.bell_fill,
                title: "Notifications",
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 20),
            _buildSectionHeader("Security & Privacy"),
            const SizedBox(height: 10),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: CupertinoIcons.lock_fill,
                title: "Change Password",
                onTap: () {},
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildSettingsTile(
                icon: CupertinoIcons.doc_text_fill,
                title: "Privacy Policy",
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(CupertinoIcons.square_arrow_right, color: Colors.white),
                label: Text(
                  "Log Out",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A helper widget to create styled section headers
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  // A helper widget to create the card container
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ClipRRect is used to ensure the children (like ListTile)
      // respect the rounded corners of the container.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  // A helper widget for consistently styled list tiles
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryOrange),
      title: Text(title),
      trailing: const Icon(CupertinoIcons.right_chevron, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}