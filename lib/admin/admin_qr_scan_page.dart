import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    _manualQrController.dispose();
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
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
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
    // On web (Chrome), MobileScanner may not work — show manual input
    if (kIsWeb) {
      return _buildWebScanner();
    }
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

  final TextEditingController _manualQrController = TextEditingController();
  Map<String, dynamic>? _lastScanResult;

  // ──── Helper: safe string from dynamic (avoids _JsonMap errors) ─────
  String _str(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map) {
      // Handle address objects like {street, city, ...}
      final parts = [v['street'], v['city'], v['country']]
          .where((e) => e != null && e.toString().isNotEmpty)
          .map((e) => e.toString());
      return parts.isNotEmpty ? parts.join(', ') : v.toString();
    }
    return v.toString();
  }

  Widget _buildWebScanner() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColor.navy, Color(0xFF283593)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.qr_code_scanner, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Scanner QR Code',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Scannez avec la caméra ou entrez le code manuellement',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ═══ Two scanning options ═══
          Row(
            children: [
              // Option 1: Camera scan dialog
              Expanded(
                child: _buildOptionCard(
                  icon: Icons.camera_alt,
                  title: 'Scanner avec caméra',
                  subtitle: 'Ouvrir la caméra pour scanner',
                  color: Colors.teal,
                  onTap: _isProcessing ? null : () => _openCameraDialog(),
                ),
              ),
              const SizedBox(width: 12),
              // Option 2: Manual input
              Expanded(
                child: _buildOptionCard(
                  icon: Icons.keyboard,
                  title: 'Entrer le code',
                  subtitle: 'Coller le code QR manuellement',
                  color: AppColor.navy,
                  onTap: null, // always visible below
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Manual QR input
          TextField(
            controller: _manualQrController,
            decoration: InputDecoration(
              labelText: 'Code QR de la réservation',
              hintText: 'Collez le code ici (ex: a1b2c3d4e5f6...)',
              prefixIcon: const Icon(Icons.qr_code),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _manualQrController.clear();
                  setState(() => _lastScanResult = null);
                },
              ),
            ),
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            onSubmitted: (_) => _processManualQR(),
          ),
          const SizedBox(height: 16),

          // Action button
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _processManualQR(),
            icon: _isProcessing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle, color: Colors.white),
            label: Text(
              _isProcessing ? 'Traitement...' : 'Valider (Check-in / Check-out)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.navy,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // Result display
          if (_lastScanResult != null) _buildScanResultCard(),

          const SizedBox(height: 24),

          // Help section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.help_outline, color: AppColor.navy),
                      SizedBox(width: 8),
                      Text('Comment ça marche ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHelpStep('1', 'Le client ouvre sa réservation et affiche le QR code'),
                  _buildHelpStep('2', 'Scannez avec la caméra ou copiez le code (32 caractères hex)'),
                  _buildHelpStep('3', 'Collez-le et cliquez "Valider"'),
                  _buildHelpStep('4', 'Check-out (sortie)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _openCameraDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        bool dialogProcessing = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColor.navy,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.camera_alt, color: Colors.white),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Scanner avec caméra', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Camera view
                  SizedBox(
                    height: 350,
                    width: double.infinity,
                    child: dialogProcessing
                        ? const Center(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Validation en cours...'),
                            ],
                          ))
                        : ClipRRect(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                            child: MobileScanner(
                              onDetect: (capture) async {
                                if (dialogProcessing) return;
                                final barcodes = capture.barcodes;
                                for (final barcode in barcodes) {
                                  final code = barcode.rawValue;
                                  if (code != null && code.isNotEmpty) {
                                    setDialogState(() => dialogProcessing = true);
                                    try {
                                      final result = await BookingService.adminValidateQRCode(code);
                                      if (mounted) {
                                        Navigator.of(ctx).pop();
                                        if (result != null) {
                                          setState(() => _lastScanResult = result);
                                          final action = result['data']?['action']?.toString() ?? 'checkin';
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(action == 'checkout' ? '✅ Check-out effectué !' : '✅ Check-in effectué !'),
                                              backgroundColor: action == 'checkout' ? Colors.blue : Colors.green,
                                            ),
                                          );
                                          _loadDashboardData();
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('❌ QR code invalide ou expiré'), backgroundColor: Colors.red),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        Navigator.of(ctx).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                    break;
                                  }
                                }
                              },
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHelpStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColor.navy.withOpacity(0.1),
            child: Text(number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.navy)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildScanResultCard() {
    final data = _lastScanResult!['data'] ?? {};
    final action = _str(data['action']).isEmpty ? 'unknown' : _str(data['action']);
    final booking = data['booking'] ?? {};
    final user = booking['user'] ?? {};
    final vehicle = booking['vehicle'];
    final parking = booking['parking'] ?? {};
    final isCheckIn = action == 'checkin';
    final isCheckOut = action == 'checkout';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isCheckIn ? Colors.green.shade50 : isCheckOut ? Colors.blue.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action badge
            Row(
              children: [
                Icon(
                  isCheckIn ? Icons.login : isCheckOut ? Icons.logout : Icons.info,
                  color: isCheckIn ? Colors.green : Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCheckIn ? 'CHECK-IN EFFECTUÉ' : isCheckOut ? 'CHECK-OUT EFFECTUÉ' : action.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCheckIn ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person, 'Client', _str(user['name']).isNotEmpty ? _str(user['name']) : '${_str(user['firstName'])} ${_str(user['lastName'])}'.trim()),
            if (_str(user['email']).isNotEmpty) _buildInfoRow(Icons.email, 'Email', _str(user['email'])),
            if (vehicle != null) _buildInfoRow(Icons.directions_car, 'Véhicule', '${_str(vehicle['make'])} ${_str(vehicle['model'])} — ${_str(vehicle['licensePlate'])}'),
            _buildInfoRow(Icons.local_parking, 'Parking', _str(parking['name'])),
            if (_str(parking['address']).isNotEmpty) _buildInfoRow(Icons.location_on, 'Adresse', _str(parking['address'])),
            _buildInfoRow(Icons.info, 'Statut', _str(booking['status'])),

            // Pricing section for checkout
            if (isCheckOut && booking['pricing'] != null) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.amber, size: 20),
                        SizedBox(width: 6),
                        Text('MONTANT À ENCAISSER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.brown)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (booking['duration']?['display'] != null)
                      _buildInfoRow(Icons.timer, 'Durée', _str(booking['duration']['display'])),
                    _buildInfoRow(Icons.monetization_on, 'Tarif/h', '${_str(booking['pricing']['rate'])} DT'),
                    _buildInfoRow(Icons.receipt, 'Sous-total', '${_str(booking['pricing']['subtotal'])} DT'),
                    _buildInfoRow(Icons.percent, 'TVA (19%)', '${_str(booking['pricing']['tax'])} DT'),
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.payments, size: 22, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('TOTAL: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                        Text('${_str(booking['pricing']['total'])} DT',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _processManualQR() async {
    final code = _manualQrController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un code QR'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final result = await BookingService.adminValidateQRCode(code);
      if (result != null && mounted) {
        setState(() => _lastScanResult = result);
        final action = result['data']?['action']?.toString() ?? 'checkin';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'checkout' ? '✅ Check-out effectué !' : '✅ Check-in effectué !'),
            backgroundColor: action == 'checkout' ? Colors.blue : Colors.green,
          ),
        );
        _loadDashboardData();
      } else if (mounted) {
        setState(() => _lastScanResult = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ QR code invalide ou expiré'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }
}
