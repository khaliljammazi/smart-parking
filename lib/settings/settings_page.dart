import 'package:flutter/material.dart';
import '../utils/constanst.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColor.navy,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications, color: AppColor.navy),
            title: const Text('Notifications'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: AppColor.navy,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language, color: AppColor.navy),
            title: const Text('Langue'),
            trailing: const Text('Français'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dark_mode, color: AppColor.navy),
            title: const Text('Mode Sombre'),
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeColor: AppColor.navy,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppColor.navy),
            title: const Text('Politique de Confidentialité'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info, color: AppColor.navy),
            title: const Text('À Propos'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}