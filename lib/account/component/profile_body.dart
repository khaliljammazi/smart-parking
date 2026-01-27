import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_header.dart';
import 'profile_menu.dart';
import '../../wallet/wallet_page.dart';
import '../../vehicle/vehicle_page.dart';
import '../../authentication/auth_provider.dart';
import '../profile_edit_page.dart';
import '../../booking/booking_history_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 18),
          const ProfileHeader(),
          const ProfileMenu(iconData: Icons.person, textData: 'Informations Personnelles', page: ProfilePage()),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.directions_car_sharp, textData: 'Gérer les Véhicules', page: VehiclePage()),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.wallet, textData: 'Portefeuille', page: WalletPage()),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.history, textData: 'Historique des Réservations', page: BookingHistoryPage()),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.support_agent, textData: 'Support'),
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