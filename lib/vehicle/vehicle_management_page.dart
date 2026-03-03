import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../vehicle/vehicle_service.dart';
import '../utils/constanst.dart';
import '../parkinglist/parking_list_page.dart';
import 'vehicle_form_page.dart';
import 'vehicle_history_page.dart';
import 'vehicle_stats_page.dart';

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({super.key});

  @override
  State<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  bool _isLoading = true;
  List<dynamic> _vehicles = [];

  final Map<String, String> _typeLabels = {
    'car': 'Voiture',
    'motorcycle': 'Moto',
    'truck': 'Camion',
    'van': 'Fourgon',
    'electric': 'Électrique',
    'hybrid': 'Hybride',
  };
  final Map<String, String> _fuelLabels = {
    'petrol': 'Essence',
    'diesel': 'Diesel',
    'electric': 'Électrique',
    'hybrid': 'Hybride',
    'gas': 'GPL',
  };
  final Map<String, IconData> _typeIcons = {
    'car': Icons.directions_car,
    'motorcycle': Icons.two_wheeler,
    'truck': Icons.local_shipping,
    'van': Icons.airport_shuttle,
    'electric': Icons.electric_car,
    'hybrid': Icons.eco,
  };

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await VehicleService.getUserVehicles();
      if (vehicles != null && mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _deleteVehicle(String vehicleId, String plate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le véhicule'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le véhicule $plate ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await VehicleService.deleteVehicle(vehicleId);
      if (ok && mounted) {
        _loadVehicles();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Véhicule supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _toggleDefault(String vehicleId) async {
    final result = await VehicleService.toggleDefault(vehicleId);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Mis à jour'),
          backgroundColor: Colors.green,
        ),
      );
      _loadVehicles();
    }
  }

  Future<void> _uploadPhotos(String vehicleId) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (images.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final xFiles = images.take(3).toList();
      final result = await VehicleService.uploadPhotos(vehicleId, xFiles);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photos ajoutées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadVehicles();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'upload des photos'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _editVehicle(Map<String, dynamic> vehicle) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => VehicleFormPage(vehicle: vehicle)),
        )
        .then((_) => _loadVehicles());
  }

  void _addVehicle() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const VehicleFormPage()))
        .then((_) => _loadVehicles());
  }

  void _openHistory(Map<String, dynamic> vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VehicleHistoryPage(vehicle: vehicle)),
    );
  }

  void _openStats() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VehicleStatsPage()));
  }

  void _navigateToParking(Map<String, dynamic> vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ParkingListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        elevation: 0,
        title: const Text(
          'Mes véhicules',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            tooltip: 'Statistiques',
            onPressed: _openStats,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addVehicle,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadVehicles,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _vehicles.length,
                itemBuilder: (ctx, i) => _buildVehicleCard(_vehicles[i]),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun véhicule ajouté',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addVehicle,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter votre premier véhicule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final isDefault = vehicle['isDefault'] == true;
    final type = vehicle['type'] ?? 'car';
    final fuelType = vehicle['fuelType'] ?? 'petrol';
    final photos = (vehicle['photos'] as List<dynamic>?) ?? [];
    final insuranceExpiry = vehicle['insuranceExpiry'] != null
        ? DateTime.tryParse(vehicle['insuranceExpiry'].toString())
        : null;
    final insuranceWarning =
        insuranceExpiry != null &&
        insuranceExpiry.difference(DateTime.now()).inDays < 30;
    final insuranceExpired =
        insuranceExpiry != null && insuranceExpiry.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDefault
            ? const BorderSide(color: AppColor.orange, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // Photos carousel
          if (photos.isNotEmpty)
            SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (ctx, i) => Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        photos[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () async {
                            final ok = await VehicleService.deletePhoto(
                              vehicle['_id'],
                              i,
                            );
                            if (ok) _loadVehicles();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${i + 1}/${photos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: plate + default star + menu
                Row(
                  children: [
                    if (isDefault)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.star,
                          color: AppColor.orange,
                          size: 22,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        vehicle['licensePlate'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColor.navy,
                        ),
                      ),
                    ),
                    if (vehicle['isVerified'] == true)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        switch (v) {
                          case 'edit':
                            _editVehicle(vehicle);
                            break;
                          case 'delete':
                            _deleteVehicle(
                              vehicle['_id'],
                              vehicle['licensePlate'],
                            );
                            break;
                          case 'default':
                            _toggleDefault(vehicle['_id']);
                            break;
                          case 'photos':
                            _uploadPhotos(vehicle['_id']);
                            break;
                          case 'history':
                            _openHistory(vehicle);
                            break;
                          case 'slots':
                            _navigateToParking(vehicle);
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'default',
                          child: Row(
                            children: [
                              Icon(
                                isDefault ? Icons.star_border : Icons.star,
                                size: 20,
                                color: AppColor.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isDefault
                                    ? 'Retirer par défaut'
                                    : 'Définir par défaut',
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'photos',
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt, size: 20),
                              SizedBox(width: 8),
                              Text('Ajouter des photos'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'history',
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 20),
                              SizedBox(width: 8),
                              Text('Historique'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'slots',
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_parking,
                                size: 20,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 8),
                              Text('Trouver parking'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Make / model
                Row(
                  children: [
                    Icon(
                      _typeIcons[type] ?? Icons.directions_car,
                      color: AppColor.navy,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChip(
                      '${vehicle['year'] ?? ''}',
                      Icons.calendar_today,
                    ),
                    _buildChip(vehicle['color'] ?? '', Icons.palette),
                    _buildChip(
                      _typeLabels[type] ?? type,
                      _typeIcons[type] ?? Icons.directions_car,
                    ),
                    _buildChip(
                      _fuelLabels[fuelType] ?? fuelType,
                      Icons.local_gas_station,
                    ),
                  ],
                ),

                // Insurance warning
                if (insuranceWarning || insuranceExpired)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: insuranceExpired
                          ? Colors.red[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: insuranceExpired ? Colors.red : Colors.orange,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: insuranceExpired ? Colors.red : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insuranceExpired
                                ? 'Assurance expirée !'
                                : 'Assurance expire dans ${insuranceExpiry!.difference(DateTime.now()).inDays} jours',
                            style: TextStyle(
                              color: insuranceExpired
                                  ? Colors.red
                                  : Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Insurance info
                if (vehicle['insuranceNumber'] != null &&
                    (vehicle['insuranceNumber'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.policy, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Assurance: ${vehicle['insuranceNumber']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColor.navy),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey[200],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _getColorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey[300]!;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return AppColor.navy;
    }
  }
}
