import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../model/parking_model.dart';
import '../utils/constanst.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final Set<Marker> _markers = <Marker>{};
  final Set<Circle> _circles = <Circle>{};
  bool _hasError = false;
  String _errorMessage = '';

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(36.8065, 10.1815), // Tunis coordinates
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _addParkingMarkers();
    _addSearchRadius();
  }

  void _addParkingMarkers() {
    for (final parking in mockParkingSpots) {
      final marker = Marker(
        markerId: MarkerId(parking.id.toString()),
        position: LatLng(parking.latitude, parking.longitude),
        infoWindow: InfoWindow(
          title: parking.name,
          snippet: '${parking.pricePerHour} DT/h • ${parking.availableSpots} places',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () {
          _showParkingDetails(parking);
        },
      );
      _markers.add(marker);
    }
  }

  void _addSearchRadius() {
    const circle = Circle(
      circleId: CircleId('search_radius'),
      center: LatLng(36.8065, 10.1815),
      radius: 2000, // 2km radius
      fillColor: Color(0x1A2196F3), // Blue with 10% opacity
      strokeColor: Colors.blue,
      strokeWidth: 2,
    );
    _circles.add(circle);
  }

  void _showParkingDetails(ParkingSpot parking) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parking.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(parking.address),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(' ${parking.rating}'),
                const SizedBox(width: 16),
                Text('${parking.pricePerHour} DT/h'),
                const SizedBox(width: 16),
                Text('${parking.availableSpots} places'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Réservation pour ${parking.name}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.navy,
                ),
                child: const Text('Réserver'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Carte des Parkings'),
          backgroundColor: AppColor.navy,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Erreur de chargement de la carte',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vérifiez que la facturation est activée sur votre projet Google Cloud.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.navy,
                ),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des Parkings'),
        backgroundColor: AppColor.navy,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonction de recherche à venir')),
              );
            },
          ),
        ],
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialPosition,
        markers: _markers,
        circles: _circles,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false, // We have our own button
        zoomControlsEnabled: true,
        compassEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        backgroundColor: AppColor.navy,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    // For now, just center on Tunis. In a real app, you'd get the user's location
    const tunis = CameraPosition(
      target: LatLng(36.8065, 10.1815),
      zoom: 15.0,
    );
    await controller.animateCamera(CameraUpdate.newCameraPosition(tunis));
  }
}