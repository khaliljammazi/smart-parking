import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../model/parking_model.dart';
import '../utils/constanst.dart';

class MapPage extends StatefulWidget {
  final Function(double lat, double lng)? onLocationSelected;

  const MapPage({super.key, this.onLocationSelected});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final List<CircleMarker> _circles = [];

  // GPS related variables
  Position? _currentPosition;
  bool _isLocationLoading = false;
  bool _locationPermissionGranted = false;
  StreamSubscription<Position>? _positionStream;

  LatLng? _selectedLocation;

  static const LatLng _initialCenter = LatLng(36.8065, 10.1815); // Tunis coordinates
  static const double _initialZoom = 12.0;

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
    _mapController.dispose();
    super.dispose();
  }

  void _addParkingMarkers() {
    for (final parking in mockParkingSpots) {
      final marker = Marker(
        width: 40,
        height: 40,
        point: LatLng(parking.latitude, parking.longitude),
        child: GestureDetector(
          onTap: () => _showParkingDetails(parking),
          child: const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );
      _markers.add(marker);
    }
  }

  void _addSearchRadius() {
    final circle = CircleMarker(
      point: _initialCenter,
      radius: 2000, // 2km radius in meters
      useRadiusInMeter: true,
      color: const Color(0x1A2196F3), // Blue with 10% opacity
      borderColor: Colors.blue,
      borderStrokeWidth: 2,
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

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  List<Marker> _getAllMarkers() {
    final markers = List<Marker>.from(_markers);
    if (_selectedLocation != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: _selectedLocation!,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }
    return markers;
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
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _updateUserLocationMarker();
      }
    });
  }

  void _addUserLocationMarker() {
    if (_currentPosition != null) {
      final userMarker = Marker(
        width: 50,
        height: 50,
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _markers.add(userMarker);
        });
      }
    }
  }

  void _updateUserLocationMarker() {
    if (_currentPosition != null && mounted) {
      final userMarker = Marker(
        width: 50,
        height: 50,
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ),
        ),
      );

      setState(() {
        // Remove old user location markers
        _markers.removeWhere((marker) => 
          marker.child is Container && 
          (marker.child as Container).decoration is BoxDecoration &&
          ((marker.child as Container).decoration as BoxDecoration).color == Colors.green
        );
        _markers.add(userMarker);
      });
    }
  }

  void _goToUserLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      );
    } else {
      _getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonction de recherche à venir')),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: _initialZoom,
          minZoom: 5,
          maxZoom: 18,
          onTap: widget.onLocationSelected != null ? _onMapTap : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.smartparking.app',
            maxZoom: 19,
          ),
          CircleLayer(
            circles: _circles,
          ),
          MarkerLayer(
            markers: _getAllMarkers(),
          ),
        ],
      ),
      floatingActionButton: widget.onLocationSelected != null
          ? FloatingActionButton.extended(
              onPressed: _selectedLocation != null
                  ? () {
                      widget.onLocationSelected!(_selectedLocation!.latitude, _selectedLocation!.longitude);
                      Navigator.of(context).pop();
                    }
                  : null,
              backgroundColor: AppColor.navy,
              icon: const Icon(Icons.check),
              label: const Text('Confirmer Emplacement'),
            )
          : FloatingActionButton(
              onPressed: _goToCurrentLocation,
              backgroundColor: AppColor.navy,
              child: const Icon(Icons.my_location),
            ),
    );
  }

  void _goToCurrentLocation() {
    if (!_locationPermissionGranted) {
      _checkLocationPermission().then((_) {
        if (_locationPermissionGranted) {
          _getCurrentLocation();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de localisation requise')),
          );
        }
      });
      return;
    }

    _goToUserLocation();
  }
}