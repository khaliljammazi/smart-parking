import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_pic.dart';
import '../../utils/constanst.dart';
import '../../authentication/auth_provider.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userProfile = authProvider.userProfile;
        final displayName = userProfile != null
            ? '${userProfile['firstName'] ?? ''} ${userProfile['lastName'] ?? ''}'.trim()
            : 'User';
        final phoneNumber = userProfile?['phone'] ?? 'No phone number';

        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height / 2.4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF064789),
                Color(0xFF023B72),
                Color(0xFF022F5B),
                Color(0xFF032445)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 30.0, bottom: 45),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 20),
                const ProfilePic(),
                Column(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}