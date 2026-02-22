import 'package:flutter/material.dart';
import 'admin_service.dart';
import '../utils/constanst.dart';
import '../location/map_page.dart';
import '../model/parking_model.dart';

class ParkingFormPage extends StatefulWidget {
  final ParkingModel? parking;

  const ParkingFormPage({super.key, this.parking});

  @override
  State<ParkingFormPage> createState() => _ParkingFormPageState();
}

class _ParkingFormPageState extends State<ParkingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _totalSpotsController = TextEditingController();
  final _priceController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.parking != null) {
      _nameController.text = widget.parking!.name;
      // Parse existing address into street/city
      final parts = widget.parking!.address.split(',');
      _streetController.text = parts.isNotEmpty ? parts[0].trim() : '';
      _cityController.text = parts.length > 1 ? parts[1].trim() : 'Tunis';
      _totalSpotsController.text = widget.parking!.totalSpots.toString();
      _priceController.text = widget.parking!.pricePerHour.toString();
      _latitude = widget.parking!.latitude;
      _longitude = widget.parking!.longitude;
    } else {
      _cityController.text = 'Tunis';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _totalSpotsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(
          onLocationSelected: (lat, lng) {
            setState(() {
              _latitude = lat;
              _longitude = lng;
            });
          },
        ),
      ),
    );
  }

  Future<void> _saveParking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un emplacement')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final parkingData = {
      'name': _nameController.text,
      'address': {
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'country': 'Tunisia',
      },
      'coordinates': {
        'latitude': _latitude,
        'longitude': _longitude,
      },
      'totalSpots': int.parse(_totalSpotsController.text),
      'pricing': {
        'hourly': double.parse(_priceController.text),
      },
    };

    bool success;
    if (widget.parking != null) {
      success = await AdminService.updateParking(widget.parking!.id, parkingData);
    } else {
      final result = await AdminService.createParking(parkingData);
      success = result != null;
    }

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parking != null ? 'Modifier Parking' : 'Ajouter Parking'),
        backgroundColor: AppColor.navy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du Parking',
                  prefixIcon: Icon(Icons.local_parking),
                ),
                validator: (value) => value!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Rue / Adresse',
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Ex: Avenue Habib Bourguiba',
                ),
                validator: (value) => value!.isEmpty ? 'La rue est requise' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  prefixIcon: Icon(Icons.location_city),
                  hintText: 'Ex: Tunis',
                ),
                validator: (value) => value!.isEmpty ? 'La ville est requise' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _totalSpotsController,
                decoration: const InputDecoration(
                  labelText: 'Nombre total de places',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix par heure (DT)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _latitude != null && _longitude != null
                          ? 'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}'
                          : 'Aucun emplacement sélectionné',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _selectLocation,
                    child: const Text('Sélectionner Emplacement'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveParking,
                      child: Text(widget.parking != null ? 'Modifier' : 'Ajouter'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}