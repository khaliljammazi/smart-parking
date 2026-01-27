import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'introduction/splash_page.dart';
import 'utils/theme_provider.dart';
import 'authentication/auth_provider.dart';
import 'authentication/login_page.dart';
import 'authentication/phone_number_dialog.dart';
import 'authentication/vehicle_required_dialog.dart';
import 'bottombar/bottombar_page.dart';
import 'admin/admin_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only load dotenv on non-web platforms
  if (!kIsWeb) {
    // For mobile/desktop, we could load dotenv here if needed
    // await dotenv.load(fileName: ".env");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _handleWebOAuthCallback();
    }
  }

  Future<void> _handleWebOAuthCallback() async {
    // Handle OAuth callback from URL parameters on web
    final uri = Uri.base;
    final token = uri.queryParameters['token'];
    final provider = uri.queryParameters['provider'];

    if (token != null && provider != null) {
      // Store the token and update auth state
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.setAuthenticated(token);

      // Clean up the URL
      if (mounted) {
        // You might want to use a more sophisticated URL cleaning approach
        // For now, we'll just navigate to the home route
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        return MaterialApp(
          title: 'Parking Intelligent',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const BottomBarPage(),
            '/admin': (context) => const AdminDashboardPage(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasShownPhoneDialog = false;
  bool _hasShownVehicleDialog = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const SplashPage();
        }

        if (!authProvider.isAuthenticated) {
          return const LoginPage();
        }

        // Check if user needs to add phone number
        if (authProvider.needsPhoneNumber && !_hasShownPhoneDialog) {
          _hasShownPhoneDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPhoneNumberDialog(context);
          });
        }

        // Check if user needs to add vehicles
        if (authProvider.needsVehicles && !_hasShownVehicleDialog) {
          _hasShownVehicleDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showVehicleRequiredDialog(context);
          });
        }

        return const BottomBarPage();
      },
    );
  }

  Future<void> _showPhoneNumberDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must complete or skip
      builder: (context) => const PhoneNumberDialog(),
    );

    if (result == true) {
      // Phone number was added successfully
      // Refresh user profile
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.getToken();
      if (token != null) {
        await authProvider.setAuthenticated(token);
      }
    }
  }

  Future<void> _showVehicleRequiredDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must add a vehicle
      builder: (context) => const VehicleRequiredDialog(),
    );

    if (result == true) {
      // Vehicle was added successfully
      // Refresh vehicles
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshVehicles();
    }
  }
}
