import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../authentication/auth_provider.dart';
import '../utils/constanst.dart';
import 'admin_service.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  bool _isLoading = false;
  List<dynamic> _users = [];
  String? _selectedRole;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    final data = await AdminService.getUsers(
      role: _selectedRole,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );

    if (mounted) {
      setState(() {
        _users = data?['users'] ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete user: $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await AdminService.deleteUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'User deleted successfully' : 'Failed to delete user',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadUsers();
      }
    }
  }

  Future<void> _changeUserRole(String userId, String currentRole, String userName) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserRole = authProvider.userProfile?['role'];

    if (currentUserRole != 'super_admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only Super Admin can change user roles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String selectedRole = currentRole;
    String? newRole = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Role for $userName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select new role:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'parking_operator', child: Text('Parking Operator')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedRole = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedRole),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.navy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Role'),
            ),
          ],
        ),
      ),
    );

    if (newRole != null && newRole != currentRole) {
      final success = await AdminService.updateUserRole(userId, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'User role updated successfully' : 'Failed to update user role',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadUsers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        title: const Text(
          'Manage Users',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search and Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadUsers();
                      },
                    ),
                  ),
                  onSubmitted: (_) => _loadUsers(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Filter by Role',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All Roles'),
                          ),
                          DropdownMenuItem(value: 'user', child: Text('User')),
                          DropdownMenuItem(
                            value: 'parking_operator',
                            child: Text('Parking Operator'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedRole = value);
                          _loadUsers();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _loadUsers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                ? const Center(child: Text('No users found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(user['role']),
                            child: Text(
                              '${user['firstName']?[0] ?? ''}${user['lastName']?[0] ?? ''}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            '${user['firstName']} ${user['lastName']}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email'] ?? ''),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(
                                    user['role'],
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _formatRole(user['role']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getRoleColor(user['role']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Role change button (only for super admin)
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final currentUserRole = authProvider.userProfile?['role'];
                                  if (currentUserRole == 'super_admin') {
                                    return IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: AppColor.navy,
                                      ),
                                      onPressed: () => _changeUserRole(
                                        user['_id'],
                                        user['role'] ?? 'user',
                                        '${user['firstName']} ${user['lastName']}',
                                      ),
                                      tooltip: 'Change Role',
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                              // Delete button (not for super admin users)
                              if (user['role'] != 'super_admin')
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteUser(
                                    user['_id'],
                                    '${user['firstName']} ${user['lastName']}',
                                  ),
                                  tooltip: 'Delete User',
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'parking_operator':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String? role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'parking_operator':
        return 'Parking Operator';
      case 'admin':
        return 'Admin';
      default:
        return 'User';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
