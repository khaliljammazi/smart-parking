import 'package:flutter/material.dart';
import '../vehicle/vehicle_service.dart';
import '../utils/constanst.dart';

class VehicleFormPage extends StatefulWidget {
  final Map<String, dynamic>? vehicle;

  const VehicleFormPage({super.key, this.vehicle});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form fields
  final _licensePlateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  String _selectedColor = 'Black';

  final List<String> _colors = [
    'Black', 'White', 'Red', 'Blue', 'Green', 'Yellow', 'Orange', 'Grey', 'Purple', 'Brown'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _licensePlateController.text = widget.vehicle!['licensePlate'] ?? '';
      _makeController.text = widget.vehicle!['make'] ?? '';
      _modelController.text = widget.vehicle!['model'] ?? '';
      _yearController.text = widget.vehicle!['year']?.toString() ?? '';
      _selectedColor = widget.vehicle!['color'] ?? 'Black';
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vehicleData = {
        'licensePlate': _licensePlateController.text.trim(),
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.parse(_yearController.text.trim()),
        'color': _selectedColor,
      };

      Map<String, dynamic>? result;

      if (widget.vehicle != null) {
        // Update existing vehicle
        result = await VehicleService.updateVehicle(
          vehicleId: widget.vehicle!['_id'],
          licensePlate: vehicleData['licensePlate'] as String,
          make: vehicleData['make'] as String,
          model: vehicleData['model'] as String,
          year: vehicleData['year'] as int,
          color: vehicleData['color'] as String,
        );
      } else {
        // Create new vehicle
        result = await VehicleService.createVehicle(
          licensePlate: vehicleData['licensePlate'] as String,
          make: vehicleData['make'] as String,
          model: vehicleData['model'] as String,
          year: vehicleData['year'] as int,
          color: vehicleData['color'] as String,
        );
      }

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vehicle != null
                ? 'Vehicle updated successfully'
                : 'Vehicle added successfully'),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save vehicle')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving vehicle: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        elevation: 0,
        title: Text(
          widget.vehicle != null ? 'Edit Vehicle' : 'Add Vehicle',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // License Plate
              const Text(
                'License Plate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColor.navy,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _licensePlateController,
                decoration: InputDecoration(
                  hintText: 'e.g., 123 TUN 456',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'License plate is required';
                  }
                  // Tunisian license plate validation
                  final tunisianPlateRegex = RegExp(r'^\d{1,3}\s?[A-Z]{1,3}\s?\d{1,4}$');
                  if (!tunisianPlateRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid Tunisian license plate format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Make
              const Text(
                'Make',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColor.navy,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _makeController,
                decoration: InputDecoration(
                  hintText: 'e.g., Toyota',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Make is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Model
              const Text(
                'Model',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColor.navy,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  hintText: 'e.g., Corolla',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Model is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Year
              const Text(
                'Year',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColor.navy,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 2020',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Year is required';
                  }
                  final year = int.tryParse(value.trim());
                  if (year == null) {
                    return 'Please enter a valid year';
                  }
                  final currentYear = DateTime.now().year + 1;
                  if (year < 1900 || year > currentYear) {
                    return 'Please enter a valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Color
              const Text(
                'Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColor.navy,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedColor,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _colors.map((color) {
                  return DropdownMenuItem(
                    value: color,
                    child: Text(color),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedColor = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a color';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.vehicle != null ? 'Update Vehicle' : 'Add Vehicle',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}