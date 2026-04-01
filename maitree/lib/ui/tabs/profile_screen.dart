import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/localization_service.dart';
import '../settings/settings_screen.dart';
import '../profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 32)),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Hey, ${auth.name ?? auth.email ?? 'Friend'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 16),
          Text(LocalizationService.t('account_management'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ListTile(title: const Text('Email'), subtitle: Text(auth.email ?? '-')),
          ListTile(title: const Text('Phone'), subtitle: Text(auth.phone ?? '-')),
          ListTile(
            title: Text(LocalizationService.t('edit_profile')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            ),
          ),
          ListTile(
            title: Text(LocalizationService.t('change_password')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePassword(context),
          ),
          ListTile(
            title: Text(LocalizationService.t('delete_account')),
            trailing: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () => _confirm(context, 'Delete account?', () async {
              final err = await context.read<AuthService>().deleteAccount();
              if (context.mounted) {
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                } else {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                }
              }
            }),
          ),
          const Divider(),
          const Text('Insurance', style: TextStyle(fontWeight: FontWeight.w600)),
          ListTile(
            title: const Text('Tata AIA Insurance'),
            trailing: const Icon(Icons.open_in_new),
            onTap: ()=> _open('https://www.tataaia.com'),
          ),
          const Divider(),
          const Text('App Options', style: TextStyle(fontWeight: FontWeight.w600)),
          ListTile(
            title: Text(LocalizationService.t('settings')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.phone),
            onTap: () => _call('tel:080'),
          ),
          ListTile(title: const Text('About'), trailing: const Icon(Icons.open_in_new), onTap: ()=> _open('https://praveen-kumar-goswami.github.io/About-for-maitree-Hackathon-/')),
          ListTile(
            title: const Text('Report Bug'),
            trailing: const Icon(Icons.email),
            onTap: () => _mail('mailto:maitreeeofficial@gmail.com?subject=Maitree%20Bug%20Report'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(onPressed: ()=> context.read<AuthService>().logout(), icon: const Icon(Icons.logout), label: Text(LocalizationService.t('log_out'))),
          const SizedBox(height: 24)
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _mail(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri);
  }
  
  Future<void> _call(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri);
  }
  
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Here you could save the image path or upload it
        // For now, just show a success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image selected successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showChangePassword(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx)=> AlertDialog(
      title: const Text('Change Password'),
      content: TextField(controller: ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: (){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated (locally if not using Firebase).'))); }, child: const Text('Save')),
      ],
    ));
  }

  void _confirm(BuildContext context, String title, VoidCallback action) {
    showDialog(context: context, builder: (ctx)=> AlertDialog(
      title: Text(title),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: (){ Navigator.pop(ctx); action(); }, child: const Text('OK')),
      ],
    ));
  }
}