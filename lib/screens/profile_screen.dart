import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? '';
      _email = prefs.getString('user_email') ?? '';
      _phone = prefs.getString('user_phone') ?? '';
    });
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await Provider.of<AuthService>(context, listen: false).logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = Provider.of<ThemeService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 36, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(_name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(_email, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            Text(_phone, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 32),
            
            // Storage Details
            _sectionTitle('Storage'),
            Card(
              child: Column(
                children: [
                  _storageTile('Messages', '2.4 MB', Icons.message),
                  _storageTile('Media', '12.8 MB', Icons.perm_media),
                  _storageTile('Cache', '1.1 MB', Icons.storage),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App Theme
            _sectionTitle('Appearance'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('App Theme'),
                    subtitle: Text(
                      themeService.themeMode == ThemeMode.light
                          ? 'Light'
                          : themeService.themeMode == ThemeMode.dark
                              ? 'Dark'
                              : 'System',
                    ),
                    trailing: PopupMenuButton<ThemeMode>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: themeService.setThemeMode,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: ThemeMode.system, child: Text('System')),
                        PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
                        PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.format_size),
                    title: const Text('Font Size'),
                    subtitle: Slider(
                      value: themeService.fontSize,
                      min: 12,
                      max: 20,
                      divisions: 4,
                      label: themeService.fontSize.toStringAsFixed(0),
                      onChanged: themeService.setFontSize,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.font_download_outlined),
                    title: const Text('Font Style'),
                    subtitle: Text(themeService.fontFamily),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: themeService.setFontFamily,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'Roboto', child: Text('Roboto')),
                        PopupMenuItem(value: 'sans-serif', child: Text('Sans Serif')),
                        PopupMenuItem(value: 'monospace', child: Text('Monospace')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        ),
      );

  Widget _storageTile(String label, String size, IconData icon) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(size, style: const TextStyle(color: Colors.grey)),
      );
}
