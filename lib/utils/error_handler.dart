import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ErrorHandler {
  // Show user-friendly error dialog
  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Réessayer'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show user-friendly error snackbar
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  // Parse HTTP error responses
  static String parseHttpError(dynamic error, int? statusCode) {
    if (kDebugMode) {
      print('HTTP Error: $error (Status: $statusCode)');
    }

    if (statusCode == null) {
      return 'Erreur de connexion. Vérifiez votre connexion internet.';
    }

    switch (statusCode) {
      case 400:
        return 'Requête invalide. Vérifiez les données saisies.';
      case 401:
        return 'Non autorisé. Veuillez vous reconnecter.';
      case 403:
        return 'Accès refusé.';
      case 404:
        return 'Ressource non trouvée.';
      case 408:
        return 'Délai d\'attente dépassé. Réessayez plus tard.';
      case 429:
        return 'Trop de requêtes. Veuillez patienter.';
      case 500:
        return 'Erreur serveur. Réessayez plus tard.';
      case 503:
        return 'Service temporairement indisponible.';
      default:
        return 'Une erreur est survenue. Code: $statusCode';
    }
  }

  // Handle API call with retry logic
  static Future<T?> handleApiCall<T>({
    required Future<T?> Function() apiCall,
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int retryCount = 0;
    
    while (retryCount <= maxRetries) {
      try {
        final result = await apiCall();
        return result;
      } catch (e) {
        if (kDebugMode) {
          print('API call failed (attempt ${retryCount + 1}): $e');
        }
        
        if (retryCount < maxRetries) {
          retryCount++;
          await Future.delayed(retryDelay);
        } else {
          if (kDebugMode) {
            print('Max retries reached');
          }
          rethrow;
        }
      }
    }
    
    return null;
  }

  // Log errors in debug mode only
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('=== ERROR in $context ===');
      print('Error: $error');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
      print('========================');
    }
  }

  // Get user-friendly message for common errors
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socket')) {
      return 'Problème de connexion réseau';
    } else if (errorString.contains('timeout')) {
      return 'Délai d\'attente dépassé';
    } else if (errorString.contains('format')) {
      return 'Format de données invalide';
    } else if (errorString.contains('permission')) {
      return 'Permission refusée';
    } else if (errorString.contains('not found')) {
      return 'Ressource introuvable';
    } else {
      return 'Une erreur est survenue';
    }
  }

  // Show success message
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show warning message
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show info message
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Handle navigation errors
  static void handleNavigationError(BuildContext context) {
    showErrorSnackBar(
      context,
      message: 'Impossible de naviguer vers cette page',
    );
  }

  // Handle form validation errors
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < minLength) {
      return 'Le mot de passe doit contenir au moins $minLength caractères';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\s'), ''))) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }
}
