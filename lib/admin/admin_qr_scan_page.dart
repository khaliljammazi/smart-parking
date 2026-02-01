import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../booking/booking_service.dart';
import '../utils/backend_api.dart';
import '../utils/constanst.dart';
import '../utils/role_helper.dart';
import '../model/parking_model.dart';
import '../authentication/auth_provider.dart';
import 'parking_form_page.dart';

class AdminQRScanPage extends StatefulWidget {
  const AdminQRScanPage({super.key});

  @override
  State<AdminQRScanPage> createState() => _AdminQRScanPageState();
}

class _AdminQRScanPageState extends State<AdminQRScanPage> with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  late TabController _tabController;
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
      setState(() {
        _userRole = role;
        // Operators only see Scanner tab, Full admins see both
        final tabCount = RoleHelper.isFullAdmin(role) ? 2 : 1;
        _tabController = TabController(length: tabCount, vsync: this);
      });
    });
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      MaterialPageRoute(builder: (context) => ParkingFormPage(parking: parking)),
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
      final success = await BackendApi.deleteParking(parking.id);
      if (success) {
        _loadDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parking supprimé')),
        );
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
            // Show validation success
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Booking validated successfully!\nUser: ${result['user']?['name'] ?? 'Unknown'}\nVehicle: ${result['vehicle']?['licensePlate'] ?? 'No vehicle'}'),
                backgroundColor: Colors.green,
              ),
            );
            _loadDashboardData(); // Refresh dashboard
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid or expired QR code'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error validating booking: $e'),
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
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isFullAdmin ? 'Admin Panel' : 'QR Scanner'),
        backgroundColor: AppColor.navy,
        bottom: isFullAdmin 
          ? TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Scanner'),
              ],
            )
          : null,
      ),
      body: isFullAdmin 
        ? TabBarView(
            controller: _tabController,
            children: [
              _buildDashboard(),
              _buildScanner(),
            ],
          )
        : _buildScanner(), // Operators only see scanner
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
              'Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Spots',
                    _totalSpots.toString(),
                    Icons.local_parking,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Available Spots',
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
                    'Taken Spots',
                    _takenSpots.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Turnover',
                    '${_turnover.toStringAsFixed(2)} DT',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Parking Places',
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
                      leading: const Icon(Icons.local_parking, color: AppColor.navy),
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
              child: const Text('Refresh'),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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
        MobileScanner(
          onDetect: _onDetect,
        ),
        if (_isProcessing)
          const Center(
            child: CircularProgressIndicator(),
          )
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