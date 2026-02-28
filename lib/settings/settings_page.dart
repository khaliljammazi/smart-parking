import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constanst.dart';
import '../utils/theme_provider.dart';
import '../utils/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColor.navy,
      ),
      body: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, langProvider, child) {
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications, color: AppColor.navy),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeThumbColor: AppColor.navy,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language, color: AppColor.navy),
                title: const Text('Langue'),
                subtitle: Text(
                  langProvider.languageCode == 'fr' ? 'Français' : 'English',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColor.navy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FR',
                        style: TextStyle(
                          fontWeight: langProvider.languageCode == 'fr' ? FontWeight.bold : FontWeight.normal,
                          color: langProvider.languageCode == 'fr' ? AppColor.navy : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Switch(
                          value: langProvider.languageCode == 'en',
                          onChanged: (_) => langProvider.toggleLanguage(),
                          activeThumbColor: AppColor.navy,
                          activeTrackColor: AppColor.navy.withOpacity(0.3),
                        ),
                      ),
                      Text(
                        'EN',
                        style: TextStyle(
                          fontWeight: langProvider.languageCode == 'en' ? FontWeight.bold : FontWeight.normal,
                          color: langProvider.languageCode == 'en' ? AppColor.navy : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () => langProvider.toggleLanguage(),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: AppColor.navy,
                ),
                title: const Text('Mode Sombre'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  activeThumbColor: AppColor.navy,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: AppColor.navy),
                title: const Text('Politique de Confidentialité'),
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }
}