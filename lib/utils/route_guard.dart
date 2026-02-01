import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../authentication/auth_provider.dart';
import 'role_helper.dart';

/// Route guard widget that protects admin routes
/// Redirects non-admin users to home page
class AdminRouteGuard extends StatelessWidget {
  final Widget child;
  
  const AdminRouteGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final role = auth.userProfile?['role'];
        
        if (!RoleHelper.isAdmin(role)) {
          // Schedule navigation for after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Access denied. Admin privileges required.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
              Navigator.of(context).pushReplacementNamed('/home');
            }
          });
          
          // Show loading while redirecting
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking permissions...'),
                ],
              ),
            ),
          );
        }
        
        return child;
      },
    );
  }
}

/// Route guard for super admin only pages
class SuperAdminRouteGuard extends StatelessWidget {
  final Widget child;
  
  const SuperAdminRouteGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final role = auth.userProfile?['role'];
        
        if (!RoleHelper.isSuperAdmin(role)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Access denied. Super Admin privileges required.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
              Navigator.of(context).pop();
            }
          });
          
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking permissions...'),
                ],
              ),
            ),
          );
        }
        
        return child;
      },
    );
  }
}

/// Widget that only shows its child if user has required role
class RoleGatedWidget extends StatelessWidget {
  final Widget child;
  final bool Function(String?) roleCheck;
  final Widget? fallback;
  
  const RoleGatedWidget({
    required this.child,
    required this.roleCheck,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final role = auth.userProfile?['role'];
        
        if (roleCheck(role)) {
          return child;
        }
        
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
