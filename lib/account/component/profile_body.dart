import 'package:flutter/material.dart';
import 'profile_header.dart';
import 'profile_menu.dart';
import '../../wallet/wallet_page.dart';
import '../../vehicle/vehicle_page.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 18),
          const ProfileHeader(),
          const ProfileMenu(iconData: Icons.person, textData: 'Informations Personnelles'),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.directions_car_sharp, textData: 'Gérer les Véhicules', page: VehiclePage()),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.wallet, textData: 'Portefeuille', page: WalletPage()),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.history, textData: 'Historique des Réservations'),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.support_agent, textData: 'Support'),
          const Divider(height: 8),
          const ProfileMenu(iconData: Icons.settings, textData: 'Paramètres'),
        ],
      ),
    );
  }
}