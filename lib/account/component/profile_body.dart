import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_header.dart';
import 'profile_menu.dart';
import '../../authentication/auth_provider.dart';
import '../profile_edit_page.dart';
import '../../booking/booking_history_page.dart';
import '../../booking/parking_stats_page.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.support_agent, color: Colors.blue.shade700, size: 28),
            const SizedBox(width: 12),
            const Text('Support Client', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vous pouvez contacter notre support client par mail ou téléphone :',
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () async {
                final uri = Uri(scheme: 'mailto', path: 'Balssem.Zoghbi@keyrus.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Balssem.Zoghbi@keyrus.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final uri = Uri(scheme: 'tel', path: '+21629930536');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: Row(
                children: [
                  Icon(Icons.phone, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    '+216 29 930 536',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 18),
          const ProfileHeader(),
          const ProfileMenu(iconData: Icons.person, textData: 'Informations Personnelles', page: ProfilePage()),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.history, textData: 'Historique des Réservations', page: BookingHistoryPage()),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.bar_chart, textData: 'Mes Statistiques', page: ParkingStatsPage()),
          const Divider(height: 8),
          Builder(
            builder: (context) => ProfileMenu(
              iconData: Icons.support_agent,
              textData: 'Support',
              onTapOverride: () => _showSupportDialog(context),
            ),
          ),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.settings, textData: 'Paramètres'),
          const Divider(height: 8),
          InkWell(
            onTap: () => _handleLogout(context),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 18.0),
                          child: Icon(Icons.logout, color: Colors.red),
                        ),
                        Text(
                          'Déconnexion',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}