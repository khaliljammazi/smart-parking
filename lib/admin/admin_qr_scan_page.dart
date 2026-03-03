import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../booking/booking_service.dart';
import '../utils/backend_api.dart';
import '../utils/constanst.dart';
import '../utils/role_helper.dart';
import '../model/parking_model.dart';
import '../authentication/auth_provider.dart';
import 'admin_service.dart';
import 'parking_form_page.dart';

class AdminQRScanPage extends StatefulWidget {
  const AdminQRScanPage({super.key});

  @override
  State<AdminQRScanPage> createState() => _AdminQRScanPageState();
}

class _AdminQRScanPageState extends State<AdminQRScanPage>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  TabController? _tabController;
  String? _userRole;

  // Dashboard data
  int _totalSpots = 0;
  int _availableSpots = 0;
  int _takenSpots = 0;
  double _turnover = 0.0;
  List<ParkingModel> _parkings = [];
  bool _isLoadingDashboard = true;

  @override
  void initState() {
    super.initState();
    // Get user role to determine tab count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.userProfile?['role'];
      if (mounted) {
        setState(() {
          _userRole = role;
          // Both admins and operators get dashboard + scanner tabs
          final showTabs =
              RoleHelper.isFullAdmin(role) || role == 'parking_operator';
          final tabCount = showTabs ? 2 : 1;
          _tabController = TabController(length: tabCount, vsync: this);
        });
      }
    });
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoadingDashboard = true);
    try {
      // Get all parkings
      final parkings = await BackendApi.getAllParkingSpots();
      _parkings = parkings;
      _totalSpots = parkings.fold(0, (sum, p) => sum + p.totalSpots);
      _availableSpots = parkings.fold(0, (sum, p) => sum + p.availableSpots);
      _takenSpots = _totalSpots - _availableSpots;

      // Get all bookings for turnover
      final bookings = await BackendApi.getAllBookings();
      _turnover = bookings
          .where((b) => b['status'] == 'completed')
          .fold(0.0, (sum, b) => sum + (b['totalPrice'] ?? 0.0));
    } catch (e) {
      print('Error loading dashboard: $e');
    }
    setState(() => _isLoadingDashboard = false);
  }

  void _addParking() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ParkingFormPage()),
    );
    if (result == true) {
      _loadDashboardData();
    }
  }

  void _editParking(ParkingModel parking) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParkingFormPage(parking: parking),
      ),
    );
    if (result == true) {
      _loadDashboardData();
    }
  }

  void _deleteParking(ParkingModel parking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer Parking'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${parking.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await AdminService.deleteParking(parking.id);
      if (success) {
        _loadDashboardData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Parking supprimé')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression')),
        );
      }
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null) {
        try {
          // Validate the booking by scanning QR code
          final result = await BookingService.adminValidateQRCode(code);
          if (result != null && mounted) {
            final data = result['data'];
            final action = data?['action'] ?? 'checkin';
            final booking = data?['booking'] ?? {};
            final userName = booking['user']?['name'] ?? 'Inconnu';
            final vehicle = booking['vehicle']?['licensePlate'] ?? 'Aucun';
            final status = booking['status'] ?? '';

            final isCheckout = action == 'checkout';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isCheckout
                      ? 'Check-out effectué !\nClient : $userName\nVéhicule : $vehicle\nStatut : Terminé'
                      : 'Check-in effectué — Réservation activée !\nClient : $userName\nVéhicule : $vehicle\nStatut : $status',
                ),
                backgroundColor: isCheckout ? Colors.blue : Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
            _loadDashboardData(); // Refresh dashboard
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR code invalide ou expiré'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur de validation : $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isFullAdmin = RoleHelper.isFullAdmin(_userRole);
    final isOperator = _userRole == 'parking_operator';
    final showTabs = isFullAdmin || isOperator;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isFullAdmin
              ? 'Panneau Admin'
              : isOperator
              ? 'Panneau Opérateur'
              : 'Scanner QR',
        ),
        backgroundColor: AppColor.navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Déconnexion',
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
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
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
        bottom: showTabs && _tabController != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Tableau de bord'),
                  Tab(text: 'Scanner'),
                ],
              )
            : null,
      ),
      body: showTabs && _tabController != null
          ? TabBarView(
              controller: _tabController,
              children: [
                isOperator ? _buildOperatorDashboard() : _buildDashboard(),
                _buildScanner(),
              ],
            )
          : _buildScanner(),
    );
  }

  Widget _buildDashboard() {
    if (_isLoadingDashboard) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tableau de bord',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Places totales',
                    _totalSpots.toString(),
                    Icons.local_parking,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Places disponibles',
                    _availableSpots.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Places occupées',
                    _takenSpots.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Chiffre d\'affaires',
                    '${_turnover.toStringAsFixed(2)} DT',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Parkings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _parkings.length,
                itemBuilder: (context, index) {
                  final parking = _parkings[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(
                        Icons.local_parking,
                        color: AppColor.navy,
                      ),
                      title: Text(parking.name),
                      subtitle: Text(parking.address),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editParking(parking),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteParking(parking),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Actualiser'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addParking,
        backgroundColor: AppColor.navy,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOperatorDashboard() {
    if (_isLoadingDashboard) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate today's expected arrivals (active bookings = expected arrivals)
    final expectedArrivals = _takenSpots;

    return RefreshIndicator(
      onRefresh: () async => _loadDashboardData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tableau de bord Opérateur',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Key metrics for operator
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Arrivées prévues',
                    expectedArrivals.toString(),
                    Icons.people_alt,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Places libres',
                    _availableSpots.toString(),
                    Icons.event_available,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Places occupées',
                    _takenSpots.toString(),
                    Icons.event_busy,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Total places',
                    _totalSpots.toString(),
                    Icons.local_parking,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Occupancy rate
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Taux d\'occupation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _totalSpots > 0 ? _takenSpots / _totalSpots : 0,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (_totalSpots > 0 ? _takenSpots / _totalSpots : 0) > 0.8
                            ? Colors.red
                            : (_totalSpots > 0
                                      ? _takenSpots / _totalSpots
                                      : 0) >
                                  0.5
                            ? Colors.orange
                            : Colors.green,
                      ),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_totalSpots > 0 ? (_takenSpots / _totalSpots * 100).toStringAsFixed(1) : 0}% occupé',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Parking list for operator view
            const Text(
              'Détails des parkings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._parkings.map(
              (parking) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: parking.availableSpots > 0
                        ? Colors.green
                        : Colors.red,
                    child: Icon(
                      parking.availableSpots > 0 ? Icons.check : Icons.close,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(parking.name),
                  subtitle: Text(parking.address),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${parking.availableSpots}/${parking.totalSpots}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('disponibles', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(onDetect: _onDetect),
        if (_isProcessing)
          const Center(child: CircularProgressIndicator())
        else
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Scannez le QR code de la réservation',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
