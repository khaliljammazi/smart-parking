import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'introduction/splash_page.dart';
import 'utils/theme_provider.dart';
import 'utils/route_guard.dart';
import 'utils/app_localizations.dart';
import 'utils/favorites_provider.dart';
import 'utils/notification_service.dart';
import 'notification/backend_notification_service.dart';
import 'authentication/auth_provider.dart';
import 'authentication/login_page.dart';
import 'authentication/forgot_password_page.dart';
import 'authentication/phone_number_dialog.dart';
import 'authentication/vehicle_required_dialog.dart';
import 'authentication/signup_page.dart';
import 'authentication/email_verification_page.dart';
import 'vehicle/vehicle_provider.dart';
import 'bottombar/bottombar_page.dart';
import 'admin/admin_dashboard_page.dart';
import 'account/settings_page.dart';
import 'notification/notification_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and notifications
  if (!kIsWeb) {
    try {
      await NotificationService.initialize();
    } catch (e) {
      if (kIsWeb) {
        print('Firebase not available on web: $e');
      }
    }
    // Initialize backend notification service
    final backendNotifications = BackendNotificationService();
    await backendNotifications.initialize();
    backendNotifications.startPolling();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
 ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (context) => FavoritesProvider(),
          update: (context, auth, favorites) {
            if (auth.isAuthenticated) {
              favorites?.syncWithBackend();
            } else {
              favorites?.clearFavorites();
            }
            return favorites!;
          },
        ),        ChangeNotifierProvider(create: (context) => VehicleProvider()),
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

      // Clean up the URL and route based on role
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Check user role and route accordingly
          final user = authProvider.userProfile;
          if (user != null &&
              (user['role'] == 'admin' ||
                  user['role'] == 'super_admin' ||
                  user['role'] == 'parking_operator')) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/admin', (route) => false);
          } else {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, AuthProvider, LanguageProvider>(
      builder: (context, themeProvider, authProvider, languageProvider, child) {
        return MaterialApp(
          title: 'Parking Intelligent',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          // Localization setup
          locale: languageProvider.locale,
          supportedLocales: const [
            Locale('fr'), // French (default)
            Locale('en'), // English
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthWrapper(),
          routes: {
            // Public routes — always accessible
            '/login': (context) => const LoginPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/signup': (context) => const SignUpPage(),
            '/verify-email': (context) => const EmailVerificationPage(),
            // Protected routes — require authentication
            '/home': (context) =>
                const AuthRouteGuard(child: BottomBarPage()),
            '/admin': (context) => const AuthRouteGuard(
                child: AdminRouteGuard(child: AdminDashboardPage())),
            '/settings': (context) =>
                const AuthRouteGuard(child: SettingsPage()),
            '/notifications': (context) =>
                const AuthRouteGuard(child: NotificationPage()),
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
  bool _hasRedirectedAdmin = false;

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

        // Check if user is admin/operator and redirect to admin dashboard
        final userRole = authProvider.userProfile?['role'];
        if (!_hasRedirectedAdmin &&
            (userRole == 'admin' ||
                userRole == 'super_admin' ||
                userRole == 'parking_operator')) {
          _hasRedirectedAdmin = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/admin', (route) => false);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user needs to add phone number (only for normal users)
        final isNormalUser = userRole == null || userRole == 'user';
        if (isNormalUser && authProvider.needsPhoneNumber && !_hasShownPhoneDialog) {
          _hasShownPhoneDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPhoneNumberDialog(context);
          });
        }

        // Check if user needs to add vehicles (only for normal users)
        if (isNormalUser && authProvider.needsVehicles && !_hasShownVehicleDialog) {
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
