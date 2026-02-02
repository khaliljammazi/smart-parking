import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'app_name': 'Smart Parking',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      'clear': 'Clear',
      'back': 'Back',
      'next': 'Next',
      'done': 'Done',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'retry': 'Retry',
      'close': 'Close',

      // Auth
      'login': 'Login',
      'logout': 'Logout',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'reset_password': 'Reset Password',
      'new_password': 'New Password',
      'login_with_email': 'Login with Email',
      'login_with_google': 'Continue with Google',
      'back_to_social_login': 'Back to Social Login',
      'remember_me': 'Remember me',
      'email_required': 'Email is required',
      'invalid_email': 'Please enter a valid email address',
      'password_required': 'Password is required',
      'password_min_length': 'Password must be at least 6 characters',
      'invalid_credentials': 'Invalid email or password. Please try again.',
      'network_error': 'Network error. Please check your connection.',
      'login_failed': 'Login failed. Please try again.',
      'otp_sent': 'OTP sent to your email',
      'enter_otp': 'Enter OTP',
      'verify_otp': 'Verify OTP',
      'resend_otp': 'Resend OTP',
      'otp_expired': 'OTP expired. Please request a new one.',

      // Home
      'home': 'Home',
      'welcome': 'Welcome',
      'find_parking': 'Find Parking',
      'nearby_parking': 'Nearby Parking',
      'popular_parking': 'Popular Parking',
      'see_all': 'See All',
      'no_parking_found': 'No parking found',

      // Parking
      'parking_spots': 'Parking Spots',
      'available_spots': 'Available Spots',
      'total_spots': 'Total Spots',
      'price_per_hour': 'Price per Hour',
      'distance': 'Distance',
      'rating': 'Rating',
      'reviews': 'Reviews',
      'amenities': 'Amenities',
      'book_now': 'Book Now',
      'view_on_map': 'View on Map',
      'directions': 'Directions',
      'parking_details': 'Parking Details',
      'no_results': 'No results found',
      'try_adjusting_filters': 'Try adjusting your filters',

      // Booking
      'my_bookings': 'My Bookings',
      'booking_details': 'Booking Details',
      'booking_confirmed': 'Booking Confirmed',
      'booking_cancelled': 'Booking Cancelled',
      'cancel_booking': 'Cancel Booking',
      'active_bookings': 'Active Bookings',
      'past_bookings': 'Past Bookings',
      'upcoming_bookings': 'Upcoming Bookings',
      'no_bookings': 'No bookings yet',
      'select_date': 'Select Date',
      'select_time': 'Select Time',
      'start_time': 'Start Time',
      'end_time': 'End Time',
      'duration': 'Duration',
      'total_price': 'Total Price',
      'booking_summary': 'Booking Summary',
      'confirm_booking': 'Confirm Booking',
      'payment': 'Payment',
      'qr_code': 'QR Code',
      'show_qr': 'Show QR Code',
      'scan_qr': 'Scan QR Code',

      // Vehicle
      'my_vehicles': 'My Vehicles',
      'add_vehicle': 'Add Vehicle',
      'edit_vehicle': 'Edit Vehicle',
      'delete_vehicle': 'Delete Vehicle',
      'vehicle_type': 'Vehicle Type',
      'make': 'Make',
      'model': 'Model',
      'license_plate': 'License Plate',
      'color': 'Color',
      'select_vehicle': 'Select Vehicle',
      'no_vehicles': 'No vehicles added yet',
      'vehicle_added': 'Vehicle added successfully',
      'vehicle_deleted': 'Vehicle deleted successfully',

      // Profile
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'personal_info': 'Personal Information',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'phone_number': 'Phone Number',
      'email_address': 'Email Address',
      'change_password': 'Change Password',
      'profile_updated': 'Profile updated successfully',

      // Settings
      'settings': 'Settings',
      'appearance': 'Appearance',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'language': 'Language',
      'notifications': 'Notifications',
      'push_notifications': 'Push Notifications',
      'booking_reminders': 'Booking Reminders',
      'promotions': 'Promotions & Offers',
      'account': 'Account',
      'payment_methods': 'Payment Methods',
      'help_support': 'Help & Support',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'about': 'About',
      'version': 'Version',

      // Admin
      'admin_dashboard': 'Admin Dashboard',
      'manage_users': 'Manage Users',
      'manage_parkings': 'Manage Parkings',
      'manage_admins': 'Manage Admins',
      'view_reports': 'View Reports',
      'scan_qr_code': 'Scan QR Code',
      'total_users': 'Total Users',
      'total_parkings': 'Total Parkings',
      'total_bookings': 'Total Bookings',
      'active_bookings_count': 'Active Bookings',
      'revenue': 'Revenue',
      'today_revenue': 'Today\'s Revenue',
      'monthly_revenue': 'Monthly Revenue',
      'quick_actions': 'Quick Actions',
      'overview': 'Overview',

      // Notifications
      'all_notifications': 'All',
      'booking_notifications': 'Bookings',
      'promotion_notifications': 'Promotions',
      'system_notifications': 'System',
      'mark_all_read': 'Mark All Read',
      'clear_all': 'Clear All',
      'no_notifications': 'No notifications',

      // Filters
      'price_range': 'Price Range',
      'max_distance': 'Maximum Distance',
      'min_rating': 'Minimum Rating',
      'show_available_only': 'Show Available Only',
      'apply_filters': 'Apply Filters',
      'reset_filters': 'Reset Filters',
      'sort_by': 'Sort By',
      'sort_distance': 'Distance (Nearest)',
      'sort_price_low': 'Price (Low to High)',
      'sort_price_high': 'Price (High to Low)',
      'sort_rating': 'Rating (Highest)',
      'sort_availability': 'Availability',
      'sort_name': 'Name (A-Z)',

      // Messages
      'are_you_sure': 'Are you sure?',
      'confirm_delete': 'Are you sure you want to delete this?',
      'confirm_cancel_booking': 'Are you sure you want to cancel this booking?',
      'coming_soon': 'Coming Soon',
      'feature_coming_soon': 'This feature is coming soon!',
      'no_internet': 'No internet connection',
      'something_went_wrong': 'Something went wrong',
      'please_try_again': 'Please try again',

      // Time
      'hours': 'hours',
      'minutes': 'minutes',
      'today': 'Today',
      'tomorrow': 'Tomorrow',
      'yesterday': 'Yesterday',
    },
    'fr': {
      // General
      'app_name': 'Parking Intelligent',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'add': 'Ajouter',
      'search': 'Rechercher',
      'filter': 'Filtrer',
      'sort': 'Trier',
      'clear': 'Effacer',
      'back': 'Retour',
      'next': 'Suivant',
      'done': 'Terminé',
      'yes': 'Oui',
      'no': 'Non',
      'ok': 'OK',
      'retry': 'Réessayer',
      'close': 'Fermer',

      // Auth
      'login': 'Connexion',
      'logout': 'Déconnexion',
      'register': 'Inscription',
      'email': 'Email',
      'password': 'Mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'forgot_password': 'Mot de passe oublié ?',
      'reset_password': 'Réinitialiser le mot de passe',
      'new_password': 'Nouveau mot de passe',
      'login_with_email': 'Se connecter avec Email',
      'login_with_google': 'Continuer avec Google',
      'back_to_social_login': 'Retour à la connexion sociale',
      'remember_me': 'Se souvenir de moi',
      'email_required': 'L\'email est requis',
      'invalid_email': 'Veuillez entrer une adresse email valide',
      'password_required': 'Le mot de passe est requis',
      'password_min_length':
          'Le mot de passe doit contenir au moins 6 caractères',
      'invalid_credentials':
          'Email ou mot de passe invalide. Veuillez réessayer.',
      'network_error': 'Erreur réseau. Vérifiez votre connexion.',
      'login_failed': 'Échec de la connexion. Veuillez réessayer.',
      'otp_sent': 'OTP envoyé à votre email',
      'enter_otp': 'Entrer le code OTP',
      'verify_otp': 'Vérifier OTP',
      'resend_otp': 'Renvoyer OTP',
      'otp_expired': 'OTP expiré. Veuillez en demander un nouveau.',

      // Home
      'home': 'Accueil',
      'welcome': 'Bienvenue',
      'find_parking': 'Trouver un Parking',
      'nearby_parking': 'Parkings à proximité',
      'popular_parking': 'Parkings populaires',
      'see_all': 'Voir tout',
      'no_parking_found': 'Aucun parking trouvé',

      // Parking
      'parking_spots': 'Places de Parking',
      'available_spots': 'Places disponibles',
      'total_spots': 'Places totales',
      'price_per_hour': 'Prix par heure',
      'distance': 'Distance',
      'rating': 'Note',
      'reviews': 'Avis',
      'amenities': 'Équipements',
      'book_now': 'Réserver',
      'view_on_map': 'Voir sur la carte',
      'directions': 'Itinéraire',
      'parking_details': 'Détails du parking',
      'no_results': 'Aucun résultat trouvé',
      'try_adjusting_filters': 'Essayez d\'ajuster vos filtres',

      // Booking
      'my_bookings': 'Mes Réservations',
      'booking_details': 'Détails de la réservation',
      'booking_confirmed': 'Réservation confirmée',
      'booking_cancelled': 'Réservation annulée',
      'cancel_booking': 'Annuler la réservation',
      'active_bookings': 'Réservations actives',
      'past_bookings': 'Réservations passées',
      'upcoming_bookings': 'Réservations à venir',
      'no_bookings': 'Aucune réservation',
      'select_date': 'Sélectionner la date',
      'select_time': 'Sélectionner l\'heure',
      'start_time': 'Heure de début',
      'end_time': 'Heure de fin',
      'duration': 'Durée',
      'total_price': 'Prix total',
      'booking_summary': 'Résumé de la réservation',
      'confirm_booking': 'Confirmer la réservation',
      'payment': 'Paiement',
      'qr_code': 'Code QR',
      'show_qr': 'Afficher le code QR',
      'scan_qr': 'Scanner le code QR',

      // Vehicle
      'my_vehicles': 'Mes Véhicules',
      'add_vehicle': 'Ajouter un véhicule',
      'edit_vehicle': 'Modifier le véhicule',
      'delete_vehicle': 'Supprimer le véhicule',
      'vehicle_type': 'Type de véhicule',
      'make': 'Marque',
      'model': 'Modèle',
      'license_plate': 'Plaque d\'immatriculation',
      'color': 'Couleur',
      'select_vehicle': 'Sélectionner un véhicule',
      'no_vehicles': 'Aucun véhicule ajouté',
      'vehicle_added': 'Véhicule ajouté avec succès',
      'vehicle_deleted': 'Véhicule supprimé avec succès',

      // Profile
      'profile': 'Profil',
      'edit_profile': 'Modifier le profil',
      'personal_info': 'Informations personnelles',
      'first_name': 'Prénom',
      'last_name': 'Nom',
      'phone_number': 'Numéro de téléphone',
      'email_address': 'Adresse email',
      'change_password': 'Changer le mot de passe',
      'profile_updated': 'Profil mis à jour avec succès',

      // Settings
      'settings': 'Paramètres',
      'appearance': 'Apparence',
      'dark_mode': 'Mode sombre',
      'light_mode': 'Mode clair',
      'language': 'Langue',
      'notifications': 'Notifications',
      'push_notifications': 'Notifications push',
      'booking_reminders': 'Rappels de réservation',
      'promotions': 'Promotions et offres',
      'account': 'Compte',
      'payment_methods': 'Méthodes de paiement',
      'help_support': 'Aide et support',
      'privacy_policy': 'Politique de confidentialité',
      'terms_of_service': 'Conditions d\'utilisation',
      'about': 'À propos',
      'version': 'Version',

      // Admin
      'admin_dashboard': 'Tableau de bord Admin',
      'manage_users': 'Gérer les utilisateurs',
      'manage_parkings': 'Gérer les parkings',
      'manage_admins': 'Gérer les admins',
      'view_reports': 'Voir les rapports',
      'scan_qr_code': 'Scanner le code QR',
      'total_users': 'Utilisateurs totaux',
      'total_parkings': 'Parkings totaux',
      'total_bookings': 'Réservations totales',
      'active_bookings_count': 'Réservations actives',
      'revenue': 'Revenus',
      'today_revenue': 'Revenus du jour',
      'monthly_revenue': 'Revenus mensuels',
      'quick_actions': 'Actions rapides',
      'overview': 'Aperçu',

      // Notifications
      'all_notifications': 'Tout',
      'booking_notifications': 'Réservations',
      'promotion_notifications': 'Promotions',
      'system_notifications': 'Système',
      'mark_all_read': 'Tout marquer comme lu',
      'clear_all': 'Tout effacer',
      'no_notifications': 'Aucune notification',

      // Filters
      'price_range': 'Fourchette de prix',
      'max_distance': 'Distance maximale',
      'min_rating': 'Note minimale',
      'show_available_only': 'Afficher uniquement les disponibles',
      'apply_filters': 'Appliquer les filtres',
      'reset_filters': 'Réinitialiser les filtres',
      'sort_by': 'Trier par',
      'sort_distance': 'Distance (plus proche)',
      'sort_price_low': 'Prix (croissant)',
      'sort_price_high': 'Prix (décroissant)',
      'sort_rating': 'Note (meilleure)',
      'sort_availability': 'Disponibilité',
      'sort_name': 'Nom (A-Z)',

      // Messages
      'are_you_sure': 'Êtes-vous sûr ?',
      'confirm_delete': 'Êtes-vous sûr de vouloir supprimer ceci ?',
      'confirm_cancel_booking':
          'Êtes-vous sûr de vouloir annuler cette réservation ?',
      'coming_soon': 'Bientôt disponible',
      'feature_coming_soon': 'Cette fonctionnalité sera bientôt disponible !',
      'no_internet': 'Pas de connexion internet',
      'something_went_wrong': 'Une erreur s\'est produite',
      'please_try_again': 'Veuillez réessayer',

      // Time
      'hours': 'heures',
      'minutes': 'minutes',
      'today': 'Aujourd\'hui',
      'tomorrow': 'Demain',
      'yesterday': 'Hier',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['fr']?[key] ??
        key;
  }

  // Shorthand for translate
  String tr(String key) => translate(key);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Language provider to manage app language
class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'app_language';
  Locale _locale = const Locale('fr'); // Default to French

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  String get languageName {
    switch (_locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return 'Français';
    }
  }

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_languageKey) ?? 'fr';
    _locale = Locale(langCode);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  void toggleLanguage() {
    setLanguage(_locale.languageCode == 'fr' ? 'en' : 'fr');
  }
}

/// Extension for easy access to translations
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  String tr(String key) => AppLocalizations.of(this)?.translate(key) ?? key;
}
