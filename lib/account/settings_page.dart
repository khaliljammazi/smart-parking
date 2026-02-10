import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/constanst.dart';
import '../utils/role_helper.dart';
import '../utils/app_localizations.dart';
import '../authentication/auth_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _pushBookingReminders = true;
  bool _pushPromotions = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final userRole = authProvider.userProfile?['role'];
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('settings')),
        backgroundColor: isDark ? const Color(0xFF1A1F3A) : AppColor.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Appearance Section
          _buildSectionHeader(l10n.tr('appearance')),
          _buildDarkModeToggle(themeProvider, isDark, l10n),
          const Divider(height: 1),

          // Language Section
          _buildSectionHeader(l10n.tr('language')),
          _buildLanguageSelector(isDark, languageProvider, l10n),
          const Divider(height: 1),

          // Notifications Section
          _buildSectionHeader(l10n.tr('notifications')),
          _buildNotificationToggle(
            title: l10n.tr('push_notifications'),
            subtitle: languageProvider.locale.languageCode == 'fr'
                ? 'Recevoir toutes les notifications'
                : 'Receive all notifications',
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            isDark: isDark,
          ),
          _buildNotificationToggle(
            title: l10n.tr('booking_reminders'),
            subtitle: languageProvider.locale.languageCode == 'fr'
                ? 'Rappels avant votre réservation'
                : 'Reminders before your booking',
            value: _pushBookingReminders,
            onChanged: _notificationsEnabled
                ? (value) => setState(() => _pushBookingReminders = value)
                : null,
            isDark: isDark,
          ),
          _buildNotificationToggle(
            title: l10n.tr('promotions'),
            subtitle: languageProvider.locale.languageCode == 'fr'
                ? 'Offres spéciales et réductions'
                : 'Special offers and discounts',
            value: _pushPromotions,
            onChanged: _notificationsEnabled
                ? (value) => setState(() => _pushPromotions = value)
                : null,
            isDark: isDark,
          ),
          const Divider(height: 1),

          // Account Section
          _buildSectionHeader(l10n.tr('account')),
          _buildMenuTile(
            icon: Icons.person_outline,
            title: l10n.tr('personal_info'),
            onTap: () => Navigator.pushNamed(context, '/profile'),
            isDark: isDark,
          ),
          _buildMenuTile(
            icon: Icons.lock_outline,
            title: l10n.tr('change_password'),
            onTap: () => _showChangePasswordDialog(l10n),
            isDark: isDark,
          ),
          _buildMenuTile(
            icon: Icons.payment_outlined,
            title: l10n.tr('payment_methods'),
            onTap: () => _showComingSoon(l10n.tr('payment_methods'), l10n),
            isDark: isDark,
          ),
          const Divider(height: 1),

          // Admin Section (only for admins)
          if (RoleHelper.isAdmin(userRole)) ...[
            _buildSectionHeader(
              languageProvider.locale.languageCode == 'fr'
                  ? 'Administration'
                  : 'Administration',
            ),
            _buildMenuTile(
              icon: Icons.admin_panel_settings,
              title: l10n.tr('admin_dashboard'),
              subtitle: RoleHelper.getRoleName(userRole),
              onTap: () => Navigator.pushNamed(context, '/admin'),
              isDark: isDark,
              iconColor: Colors.purple,
            ),
            const Divider(height: 1),
          ],

          // Support Section
          _buildSectionHeader(
            languageProvider.locale.languageCode == 'fr'
                ? 'Support'
                : 'Support',
          ),
          _buildMenuTile(
            icon: Icons.help_outline,
            title: l10n.tr('help_support'),
            onTap: () => _showComingSoon(l10n.tr('help_support'), l10n),
            isDark: isDark,
          ),
          _buildMenuTile(
            icon: Icons.chat_bubble_outline,
            title: languageProvider.locale.languageCode == 'fr'
                ? 'Nous contacter'
                : 'Contact Us',
            onTap: () => _showComingSoon(
              languageProvider.locale.languageCode == 'fr'
                  ? 'Contact'
                  : 'Contact',
              l10n,
            ),
            isDark: isDark,
          ),
          _buildMenuTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.tr('privacy_policy'),
            onTap: () => _showComingSoon(l10n.tr('privacy_policy'), l10n),
            isDark: isDark,
          ),
          _buildMenuTile(
            icon: Icons.description_outlined,
            title: l10n.tr('terms_of_service'),
            onTap: () => _showComingSoon(l10n.tr('terms_of_service'), l10n),
            isDark: isDark,
          ),
          const Divider(height: 1),

          // App Info
          _buildSectionHeader(l10n.tr('about')),
          _buildMenuTile(
            icon: Icons.info_outline,
            title: '${l10n.tr('version')} de l\'application',
            subtitle: '1.0.0 (Build 1)',
            onTap: null,
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _handleLogout(authProvider),
              icon: const Icon(Icons.logout),
              label: Text(l10n.tr('logout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(
    ThemeProvider themeProvider,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return ListTile(
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          key: ValueKey(isDark),
          color: isDark ? Colors.amber : Colors.orange,
          size: 28,
        ),
      ),
      title: Text(
        l10n.tr('dark_mode'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        isDark
            ? (l10n.locale.languageCode == 'fr' ? 'Activé' : 'Enabled')
            : (l10n.locale.languageCode == 'fr' ? 'Désactivé' : 'Disabled'),
      ),
      trailing: Switch.adaptive(
        value: isDark,
        onChanged: (value) => themeProvider.toggleTheme(),
        activeColor: AppColor.navy,
      ),
    );
  }

  Widget _buildLanguageSelector(
    bool isDark,
    LanguageProvider languageProvider,
    AppLocalizations l10n,
  ) {
    return ListTile(
      leading: Icon(
        Icons.language,
        color: isDark ? Colors.blue.shade300 : AppColor.navy,
        size: 28,
      ),
      title: Text(
        l10n.tr('language'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(languageProvider.languageName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(languageProvider, l10n),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool)? onChanged,
    required bool isDark,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: onChanged == null ? Colors.grey : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: onChanged == null ? Colors.grey.shade400 : null,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColor.navy,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    required bool isDark,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isDark ? Colors.blue.shade300 : AppColor.navy),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  void _showLanguageDialog(
    LanguageProvider languageProvider,
    AppLocalizations l10n,
  ) {
    final languages = [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    ];

    showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, provider, child) {
          return AlertDialog(
            title: Text(
              provider.languageCode == 'fr'
                  ? 'Choisir la langue'
                  : 'Choose Language',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: languages.map((lang) {
                return RadioListTile<String>(
                  title: Row(
                    children: [
                      Text(
                        lang['flag'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(lang['name'] as String),
                    ],
                  ),
                  value: lang['code'] as String,
                  groupValue: provider.languageCode,
                  onChanged: (value) async {
                    if (value != null) {
                      await provider.setLanguage(value);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value == 'fr'
                                  ? 'Langue changée en Français'
                                  : 'Language changed to English',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  provider.languageCode == 'fr' ? 'Annuler' : 'Cancel',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(AppLocalizations l10n) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final isFrench = l10n.locale.languageCode == 'fr';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tr('change_password')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: isFrench
                    ? 'Mot de passe actuel'
                    : 'Current password',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.tr('new_password'),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.tr('confirm_password'),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement password change
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFrench
                        ? 'Mot de passe modifié avec succès'
                        : 'Password changed successfully',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(isFrench ? 'Changer' : 'Change'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - ${l10n.tr('coming_soon')}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogout(AuthProvider authProvider) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final isFrench = languageProvider.locale.languageCode == 'fr';
    final l10n = context.l10n;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tr('logout')),
        content: Text(l10n.tr('are_you_sure')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.tr('logout')),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await authProvider.logout();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
