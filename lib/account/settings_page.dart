import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/constanst.dart';
import '../utils/role_helper.dart';
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
  String _selectedLanguage = 'Français';

  final List<String> _languages = [
    'Français',
    'English',
    'العربية',
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final userRole = authProvider.userProfile?['role'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: isDark ? const Color(0xFF1A1F3A) : AppColor.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Appearance Section
          _buildSectionHeader('Apparence'),
          _buildDarkModeToggle(themeProvider, isDark),
          const Divider(height: 1),
          
          // Language Section
          _buildSectionHeader('Langue'),
          _buildLanguageSelector(isDark),
          const Divider(height: 1),
          
          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildNotificationToggle(
            title: 'Notifications Push',
            subtitle: 'Recevoir toutes les notifications',
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            isDark: isDark,
          ),
          _buildNotificationToggle(
            title: 'Rappels de réservation',
            subtitle: 'Rappels avant votre réservation',
            value: _pushBookingReminders,
            onChanged: _notificationsEnabled 
                ? (value) => setState(() => _pushBookingReminders = value)
                : null,
            isDark: isDark,
          ),
          _buildNotificationToggle(
            title: 'Promotions & Offres',
            subtitle: 'Offres spéciales et réductions',
            value: _pushPromotions,
            onChanged: _notificationsEnabled 
                ? (value) => setState(() => _pushPromotions = value)
                : null,
            isDark: isDark,
          ),
          const Divider(height: 1),
          
          // Account Section
          _buildSectionHeader('Compte'),
          _buildMenuTile(
            icon: Icons.person_outline,
            title: 'Informations personnelles',
            onTap: () => Navigator.pushNamed(context, '/profile'),
            isDark: isDark,
          ),
          _buildMenuTile(
            icon: Icons.lock_outline,
            title: 'Changer le mot de passe',
            onTap: () => _showChangePasswordDialog(),
            isDark: isDark,
          ),
          _buildMenuTile(
            icon: Icons.payment_outlined,
            title: 'Méthodes de paiement',
            onTap: () => _showComingSoon('Méthodes de paiement'),
            isDark: isDark,
          ),
          const Divider(height: 1),
          
          // Admin Section (only for admins)
          if (RoleHelper.isAdmin(userRole)) ...[
            _buildSectionHeader('Administration'),
            _buildMenuTile(
              icon: Icons.admin_panel_settings,
              title: 'Tableau de bord Admin',
              subtitle: RoleHelper.getRoleName(userRole),
              onTap: () => Navigator.pushNamed(context, '/admin'),
              isDark: isDark,
              iconColor: Colors.purple,
            ),
            const Divider(height: 1),
          ],
          
          // Support Section
          _buildSectionHeader('Support'),
          _buildMenuTile(
            icon: Icons.help_outline,
            title: 'Centre d\'aide',
            onTap: () => _showComingSoon('Centre d\'aide'),
            isDark: isDark,
          ),
          _buildMenuTile(
            icon: Icons.chat_bubble_outline,
            title: 'Nous contacter',
            onTap: () => _showComingSoon('Contact'),
            isDark: isDark,
          ),
          _buildMenuTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialité',
            onTap: () => _showComingSoon('Politique de confidentialité'),
            isDark: isDark,
          ),
          _buildMenuTile(
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            onTap: () => _showComingSoon('Conditions d\'utilisation'),
            isDark: isDark,
          ),
          const Divider(height: 1),
          
          // App Info
          _buildSectionHeader('À propos'),
          _buildMenuTile(
            icon: Icons.info_outline,
            title: 'Version de l\'application',
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
              label: const Text('Déconnexion'),
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

  Widget _buildDarkModeToggle(ThemeProvider themeProvider, bool isDark) {
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
      title: const Text(
        'Mode sombre',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(isDark ? 'Activé' : 'Désactivé'),
      trailing: Switch.adaptive(
        value: isDark,
        onChanged: (value) => themeProvider.toggleTheme(),
        activeColor: AppColor.navy,
      ),
    );
  }

  Widget _buildLanguageSelector(bool isDark) {
    return ListTile(
      leading: Icon(
        Icons.language,
        color: isDark ? Colors.blue.shade300 : AppColor.navy,
        size: 28,
      ),
      title: const Text(
        'Langue',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(_selectedLanguage),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(),
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
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Langue changée en $value'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement password change
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mot de passe modifié avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Bientôt disponible'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogout(AuthProvider authProvider) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
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
