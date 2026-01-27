import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/auth_provider.dart';

class ProfilePic extends StatelessWidget {
  const ProfilePic({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userProfile = authProvider.userProfile;
        final avatarUrl = userProfile?['avatar'];

        return SizedBox(
          height: 115,
          width: 115,
          child: CircleAvatar(
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : const NetworkImage(
                    'https://cdn.pixabay.com/photo/2016/03/28/12/35/cat-1285634_1280.png',
                  ),
            onBackgroundImageError: (exception, stackTrace) {
              // Fallback to default avatar if image fails to load
            },
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  )
                : null,
          ),
        );
      },
    );
  }
}