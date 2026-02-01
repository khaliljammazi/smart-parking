/// Role-based access control helper for the Smart Parking app
/// Centralizes all permission checks to ensure consistent security
class RoleHelper {
  // Role constants
  static const String roleUser = 'user';
  static const String roleOperator = 'parking_operator';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'super_admin';

  // Role groups
  static const List<String> adminRoles = [roleAdmin, roleSuperAdmin, roleOperator];
  static const List<String> fullAdminRoles = [roleAdmin, roleSuperAdmin];
  static const List<String> qrScannerRoles = [roleAdmin, roleSuperAdmin, roleOperator];

  /// Check if the role is any type of admin (including operator)
  static bool isAdmin(String? role) => adminRoles.contains(role);

  /// Check if the role is a full admin (not operator)
  static bool isFullAdmin(String? role) => fullAdminRoles.contains(role);

  /// Check if the role is super admin
  static bool isSuperAdmin(String? role) => role == roleSuperAdmin;

  /// Check if the role is a parking operator only
  static bool isOperator(String? role) => role == roleOperator;

  /// Check if the role is a regular user
  static bool isRegularUser(String? role) => role == roleUser || role == null;

  /// Check if the user can scan QR codes
  static bool canScanQR(String? role) => qrScannerRoles.contains(role);

  /// Check if the user can manage users
  static bool canManageUsers(String? role) => fullAdminRoles.contains(role);

  /// Check if the user can manage admins
  static bool canManageAdmins(String? role) => role == roleSuperAdmin;

  /// Check if the user can manage parkings
  static bool canManageParkings(String? role) => fullAdminRoles.contains(role);

  /// Check if the user can view dashboard statistics
  static bool canViewDashboard(String? role) => adminRoles.contains(role);

  /// Check if the user can view revenue data
  static bool canViewRevenue(String? role) => fullAdminRoles.contains(role);

  /// Check if the user can change user roles
  static bool canChangeRoles(String? role) => role == roleSuperAdmin;

  /// Get user-friendly role name
  static String getRoleName(String? role) {
    switch (role) {
      case roleSuperAdmin:
        return 'Super Admin';
      case roleAdmin:
        return 'Admin';
      case roleOperator:
        return 'Parking Operator';
      case roleUser:
        return 'User';
      default:
        return 'Unknown';
    }
  }

  /// Get role badge color
  static int getRoleColor(String? role) {
    switch (role) {
      case roleSuperAdmin:
        return 0xFF9C27B0; // Purple
      case roleAdmin:
        return 0xFF2196F3; // Blue
      case roleOperator:
        return 0xFFFF9800; // Orange
      case roleUser:
        return 0xFF4CAF50; // Green
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
}
