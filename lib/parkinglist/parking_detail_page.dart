import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher_string.dart';
import '../model/parking_model.dart';
import '../utils/constanst.dart';
import '../utils/favorites_provider.dart';
import '../utils/role_helper.dart';
import '../authentication/auth_provider.dart';
import '../booking/booking_service.dart';
import '../booking/qr_code_dialog.dart';
import '../booking/rating_dialog.dart';
import '../booking/parking_reviews_widget.dart';
import '../notification/backend_notification_service.dart';
import '../vehicle/vehicle_service.dart';
import '../utils/backend_api.dart';

class ParkingDetailPage extends StatefulWidget {
  final ParkingModel parking;

  const ParkingDetailPage({super.key, required this.parking});

  @override
  State<ParkingDetailPage> createState() => _ParkingDetailPageState();
}

class _ParkingDetailPageState extends State<ParkingDetailPage> {
  bool _isReserving = false;
  late ParkingModel _parking;

  @override
  void initState() {
    super.initState();
    _parking = widget.parking;
  }

  Future<void> _refreshParking() async {
    final updated = await BackendApi.getParkingById(_parking.id);
    if (updated != null && mounted) {
      setState(() => _parking = updated);
    }
  }

  Future<void> _navigateToParking() async {
    try {
      // On web, open Google Maps in the browser directly
      if (kIsWeb) {
        final url = 'https://www.google.com/maps/search/?api=1&query=${_parking.latitude},${_parking.longitude}';
        await launchUrlString(url);
        return;
      }
      final availableMaps = await MapLauncher.installedMaps;
      if (availableMaps.isEmpty) {
        // Fallback to opening Google Maps URL if no native apps installed
        final url = 'https://www.google.com/maps/search/?api=1&query=${_parking.latitude},${_parking.longitude}';
        await launchUrlString(url);
        return;
      }

      if (availableMaps.length == 1) {
        await availableMaps.first.showDirections(
          destination: Coords(_parking.latitude, _parking.longitude),
          destinationTitle: _parking.name,
        );
      } else {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Choisir l\'application',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...availableMaps.map((map) => ListTile(
                  leading: Icon(Icons.map, color: AppColor.navy),
                  title: Text(map.mapName),
                  onTap: () {
                    Navigator.pop(context);
                    map.showDirections(
                      destination: Coords(_parking.latitude, _parking.longitude),
                      destinationTitle: _parking.name,
                    );
                  },
                )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de navigation: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _makeReservation() async {
    if (_parking.availableSpots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune place disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Fetch user vehicles and let them choose
    String? selectedVehicleId;
    try {
      final vehicles = await VehicleService.getUserVehicles();

      if (vehicles != null && vehicles.isNotEmpty) {
        if (vehicles.length == 1) {
          // Auto-select the only vehicle
          selectedVehicleId = vehicles[0]['_id']?.toString() ?? vehicles[0]['id']?.toString();
        } else {
          // Show vehicle selection dialog
          if (!mounted) return;
          selectedVehicleId = await _showVehicleSelectionDialog(vehicles);
          if (selectedVehicleId == null) return; // User cancelled
        }
      }
      // If no vehicles, proceed without vehicleId (allow reservation without vehicle)
    } catch (e) {
      // If vehicle fetch fails, proceed without vehicleId
      debugPrint('Erreur récupération véhicules: $e');
    }

    setState(() => _isReserving = true);

    try {
      final result = await BookingService.createReservation(
        parkingId: _parking.id,
        vehicleId: selectedVehicleId,
      );

      if (result != null && mounted) {
        final booking = result['data']?['booking'];
        
        if (booking != null) {
          // Send local notification for booking confirmation
          final notificationService = BackendNotificationService();
          await notificationService.showBookingConfirmation(
            parkingName: _parking.name,
            date: DateTime.now().toString().split(' ')[0],
            time: DateTime.now().toString().split(' ')[1].substring(0, 5),
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réservation créée avec succès!'),
              backgroundColor: Colors.green,
            ),
          );

          // Show QR code dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => QRCodeDialog(booking: booking),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de la réservation. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReserving = false);
      }
    }
  }

  Future<String?> _showVehicleSelectionDialog(List<dynamic> vehicles) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_car, color: AppColor.navy, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Choisir un véhicule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColor.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Sélectionnez le véhicule pour cette réservation',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...vehicles.map((vehicle) {
                final id = vehicle['_id']?.toString() ?? vehicle['id']?.toString() ?? '';
                final plate = vehicle['licensePlate'] ?? '';
                final make = vehicle['make'] ?? '';
                final model = vehicle['model'] ?? '';
                final color = vehicle['color'] ?? '';
                final year = vehicle['year']?.toString() ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColor.navy.withOpacity(0.1),
                      child: const Icon(Icons.directions_car, color: AppColor.navy),
                    ),
                    title: Text(
                      '$make $model ${year.isNotEmpty ? "($year)" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.confirmation_number, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(plate),
                        if (color.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.palette, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(color),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColor.navy),
                    onTap: () => Navigator.pop(context, id),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(_parking.id);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColor.navy,
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  favoritesProvider.toggleFavorite(_parking.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite
                            ? 'Retiré des favoris'
                            : 'Ajouté aux favoris',
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: isFavorite ? Colors.grey : Colors.green,
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _parking.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(150, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColor.navy.withOpacity(0.8),
                      AppColor.navy,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.local_parking,
                  size: 100,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Availability Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                            icon: Icons.local_parking,
                            label: 'Places disponibles',
                            value: '${_parking.availableSpots}',
                            color: _parking.availableSpots > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          _buildInfoItem(
                            icon: Icons.attach_money,
                            label: 'Prix',
                            value: '${_parking.pricePerHour} DT/h',
                            color: AppColor.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: AppColor.navy),
                              SizedBox(width: 8),
                              Text(
                                'Adresse',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.navy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _parking.address,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            _parking.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColor.navy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '/ 5.0',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          // Rate button for normal users
                          if (!RoleHelper.isAdmin(Provider.of<AuthProvider>(context, listen: false).userProfile?['role']))
                            TextButton.icon(
                              onPressed: () async {
                                final rated = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => RatingDialog(
                                    parkingId: _parking.id,
                                    parkingName: _parking.name,
                                  ),
                                );
                                if (rated == true) {
                                  await _refreshParking();
                                }
                              },
                              icon: const Icon(Icons.rate_review, color: AppColor.orange),
                              label: const Text(
                                'Évaluer',
                                style: TextStyle(color: AppColor.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Navigate Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToParking(),
                      icon: const Icon(Icons.directions, color: AppColor.navy),
                      label: const Text(
                        'Naviguer vers ce parking',
                        style: TextStyle(color: AppColor.navy, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColor.navy, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reserve Button (only for normal users, not admins)
                  if (!RoleHelper.isAdmin(Provider.of<AuthProvider>(context, listen: false).userProfile?['role']))
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isReserving ? null : _makeReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.orange,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: _isReserving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Réserver Maintenant',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reviews from other users
                  ParkingReviewsWidget(
                    parkingId: _parking.id,
                    currentRating: _parking.rating,
                  ),
                  const SizedBox(height: 16),

                  // Information Notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Un QR code sera généré pour votre réservation\n'
                          '• Présentez le QR code à l\'entrée du parking\n'
                          '• Le paiement se fait en espèces à la sortie\n'
                          '• Tarif calculé selon la durée de stationnement',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
