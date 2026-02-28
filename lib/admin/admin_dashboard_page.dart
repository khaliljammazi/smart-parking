import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../authentication/auth_provider.dart';
import '../utils/constanst.dart';
import '../utils/role_helper.dart';
import 'admin_service.dart';
import 'manage_users_page.dart';
import 'manage_admins_page.dart';
import 'admin_qr_scan_page.dart';
import 'reports_page.dart';
import '../parkinglist/parking_list_page.dart';
import '../vehicle/vehicle_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _revenueData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final dashboardData = await AdminService.getDashboardData();
      final revenueData = await AdminService.getRevenueData();

      if (mounted) {
        setState(() {
          _dashboardData = dashboardData;
          _revenueData = revenueData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        elevation: 0,
        title: const Text(
          'Tableau de bord Admin',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true && context.mounted) {
                await authProvider.logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    const Text(
                      'Actions rapides',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColor.navy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActions(user?['role']),
                    const SizedBox(height: 32),

                    // Statistics Cards
                    if (_dashboardData != null) ...[
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColor.navy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatisticsGrid(_dashboardData!['statistics']),
                      const SizedBox(height: 32),
                    ],

                    // Revenue Section
                    if (_revenueData != null) ...[
                      const Text(
                      'Analyse des revenus',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColor.navy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRevenueSummary(_revenueData!['summary']),
                      const SizedBox(height: 16),
                      _buildRevenueByParking(_revenueData!['revenueByParking']),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActions(String? userRole) {
    final isSuperAdmin = RoleHelper.isSuperAdmin(userRole);
    final isFullAdmin = RoleHelper.isFullAdmin(userRole);
    final canScanQR = RoleHelper.canScanQR(userRole);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        // QR Scanner - Only for operators and admins who can scan
        if (canScanQR)
          _buildActionCard(
            'Scanner QR',
            Icons.qr_code_scanner,
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminQRScanPage()),
            ),
          ),
        // Manage Users - Only for full admins (not operators)
        if (isFullAdmin)
          _buildActionCard(
            'Gérer les utilisateurs',
            Icons.people,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManageUsersPage()),
            ),
          ),
        // Manage Parkings - Only for full admins
        if (isFullAdmin)
          _buildActionCard(
            'Gérer les parkings',
            Icons.local_parking,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ParkingListPage()),
            ),
          ),
        // Manage Admins - Only for super admins
        if (isSuperAdmin)
          _buildActionCard(
            'Gérer les admins',
            Icons.admin_panel_settings,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManageAdminsPage()),
            ),
          ),
        // View Reports - Only for full admins
        if (isFullAdmin)
          _buildActionCard('Voir les rapports', Icons.analytics, Colors.orange, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportsPage()),
            );
          }),
        // Support Tickets / Signalements - Only for full admins
        if (isFullAdmin)
          _buildActionCard(
            'Signalements',
            Icons.report_problem,
            Colors.redAccent,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportsPage(initialTab: 3)),
            ),
          ),
        // Manage Vehicles - For admins
        if (isFullAdmin)
          _buildActionCard(
            'Gérer les véhicules',
            Icons.directions_car,
            Colors.indigo,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VehicleManagementPage()),
            ),
          ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid(Map<String, dynamic> statistics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total utilisateurs',
          statistics['totalUsers']?.toString() ?? '0',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Total parkings',
          statistics['totalParkings']?.toString() ?? '0',
          Icons.local_parking,
          Colors.green,
        ),
        _buildStatCard(
          'Total réservations',
          statistics['totalBookings']?.toString() ?? '0',
          Icons.book_online,
          Colors.orange,
        ),
        _buildStatCard(
          'Réservations actives',
          statistics['activeBookings']?.toString() ?? '0',
          Icons.access_time,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSummary(Map<String, dynamic> summary) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé des revenus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueItem(
                    'Revenu total',
                    '${summary['totalRevenue']?.toStringAsFixed(2) ?? '0'} DT',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRevenueItem(
                    'Moy. par réservation',
                    '${summary['averageRevenue']?.toStringAsFixed(2) ?? '0'} DT',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueItem(
                    'Total réservations',
                    summary['totalBookings']?.toString() ?? '0',
                    Icons.receipt,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRevenueItem(
                    'Période',
                    _formatPeriod(summary['period']),
                    Icons.calendar_today,
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByParking(List<dynamic> revenueByParking) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenus par parking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
            const SizedBox(height: 16),
            if (revenueByParking.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucune donnée de revenu disponible'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: revenueByParking.length,
                itemBuilder: (context, index) {
                  final parking = revenueByParking[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColor.orange,
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(parking['name'] ?? 'Parking inconnu'),
                    subtitle: Text('${parking['bookingCount']} réservations'),
                    trailing: Text(
                      '${parking['totalRevenue']?.toStringAsFixed(2) ?? '0'} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatPeriod(Map<String, dynamic>? period) {
    if (period == null) return 'N/A';
    final start = DateTime.parse(period['start']);
    final end = DateTime.parse(period['end']);
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }
}
