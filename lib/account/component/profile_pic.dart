import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/auth_provider.dart';
import '../../authentication/auth_service.dart';

class ProfilePic extends StatelessWidget {
  const ProfilePic({super.key});

  String _getInitials(Map<String, dynamic>? profile) {
    final first = (profile?['firstName'] ?? '').toString().trim();
    final last = (profile?['lastName'] ?? '').toString().trim();
    final initials = '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'.toUpperCase();
    return initials.isNotEmpty ? initials : '?';
  }

  String _getAvatarUrl(String avatar) {
    if (avatar.startsWith('http')) return avatar;
    final baseUrl = AuthService.baseUrl.replaceAll('/api', '');
    return '$baseUrl$avatar';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userProfile = authProvider.userProfile;
        final rawAvatar = userProfile?['avatar'];
        final hasAvatar = rawAvatar != null && rawAvatar.toString().isNotEmpty;
        final avatarUrl = hasAvatar ? _getAvatarUrl(rawAvatar.toString()) : null;

        return Container(
          height: 115,
          width: 115,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: const Color(0xFF1A237E),
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
            onBackgroundImageError: hasAvatar
                ? (exception, stackTrace) {
                    debugPrint('Avatar load error: $exception');
                  }
                : null,
            child: !hasAvatar
                ? Text(
                    _getInitials(userProfile),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}