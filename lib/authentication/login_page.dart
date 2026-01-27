import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../utils/constanst.dart';
import 'auth_provider.dart';
import 'oauth_webview.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleOAuth(String provider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String authUrl;
      if (provider == 'Google') {
        authUrl = AuthService.getGoogleAuthUrl();
      } else if (provider == 'Facebook') {
        authUrl = AuthService.getFacebookAuthUrl();
      } else {
        throw Exception('Unknown provider');
      }

      if (kIsWeb) {
        // For web, open in new tab/window
        if (await canLaunchUrl(Uri.parse(authUrl))) {
          await launchUrl(Uri.parse(authUrl), webOnlyWindowName: '_self');
        } else {
          throw Exception('Could not launch $authUrl');
        }
      } else {
        // For mobile, use webview
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OAuthWebView(
              authUrl: authUrl,
              provider: provider,
            ),
          ),
        );

        if (result == true && mounted) {
          // Authentication successful, navigate to main app
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during $provider authentication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAdminLoginDialog() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (usernameController.text == 'admin' && passwordController.text == '1234') {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid credentials')),
                );
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );

    if (result == true) {
      Navigator.of(context).pushReplacementNamed('/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Title
              const Icon(
                Icons.local_parking,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'Smart Parking',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Find and book parking spots easily',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),

              // OAuth Buttons
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              else ...[
                // Google Sign In
                ElevatedButton.icon(
                  onPressed: () => _handleOAuth('Google'),
                  icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Facebook Sign In
                ElevatedButton.icon(
                  onPressed: () => _handleOAuth('Facebook'),
                  icon: const Icon(Icons.facebook, color: Colors.white),
                  label: const Text(
                    'Continue with Facebook',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Admin Login
                ElevatedButton.icon(
                  onPressed: _showAdminLoginDialog,
                  icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                  label: const Text(
                    'Admin Login',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Terms and Privacy
              const Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}