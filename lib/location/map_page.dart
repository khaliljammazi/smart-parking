import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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

  // GPS related variables
  Position? _currentPosition;
  bool _isLocationLoading = false;
  bool _locationPermissionGranted = false;
  StreamSubscription<Position>? _positionStream;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(36.8065, 10.1815), // Tunis coordinates
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _addParkingMarkers();
    _addSearchRadius();
    _initializeLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
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

  // GPS Methods
  Future<void> _initializeLocation() async {
    await _checkLocationPermission();
    if (_locationPermissionGranted) {
      await _getCurrentLocation();
      _startLocationUpdates();
    }
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    setState(() {
      _locationPermissionGranted = permission == LocationPermission.whileInUse ||
                                   permission == LocationPermission.always;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _isLocationLoading = false;
      });

      // Add user location marker
      _addUserLocationMarker();

      // Optionally center map on user location
      // await _goToUserLocation();
    } catch (e) {
      setState(() {
        _isLocationLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de localisation: $e')),
      );
    }
  }

  void _startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _updateUserLocationMarker();
    });
  }

  void _addUserLocationMarker() {
    if (_currentPosition != null) {
      final userMarker = Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(title: 'Votre position'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );

      setState(() {
        _markers.add(userMarker);
      });
    }
  }

  void _updateUserLocationMarker() {
    if (_currentPosition != null) {
      final userMarker = Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(title: 'Votre position'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );

      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'user_location');
        _markers.add(userMarker);
      });
    }
  }

  Future<void> _goToUserLocation() async {
    if (_currentPosition != null) {
      final GoogleMapController controller = await _controller.future;
      final userLocation = CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 16.0,
      );
      await controller.animateCamera(CameraUpdate.newCameraPosition(userLocation));
    } else {
      // If no current position, try to get it
      await _getCurrentLocation();
    }
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
          if (_isLocationLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else if (_locationPermissionGranted && _currentPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Aller à ma position',
              onPressed: _goToCurrentLocation,
            )
          else
            IconButton(
              icon: const Icon(Icons.location_off),
              tooltip: 'Activer la localisation',
              onPressed: () async {
                await _checkLocationPermission();
                if (_locationPermissionGranted) {
                  await _getCurrentLocation();
                }
              },
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
    if (!_locationPermissionGranted) {
      await _checkLocationPermission();
      if (!_locationPermissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission de localisation requise')),
        );
        return;
      }
    }

    await _goToUserLocation();
  }
}