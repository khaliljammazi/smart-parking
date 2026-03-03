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
  final _insuranceNumberController = TextEditingController();
  String _selectedColor = 'Black';
  String _selectedType = 'car';
  String _selectedFuel = 'petrol';
  DateTime? _insuranceExpiry;
  bool _isDefault = false;

  final List<String> _colors = [
    'Black', 'White', 'Red', 'Blue', 'Green', 'Yellow', 'Orange', 'Grey', 'Purple', 'Brown'
  ];

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
    if (widget.vehicle != null) {
      _licensePlateController.text = widget.vehicle!['licensePlate'] ?? '';
      _makeController.text = widget.vehicle!['make'] ?? '';
      _modelController.text = widget.vehicle!['model'] ?? '';
      _yearController.text = widget.vehicle!['year']?.toString() ?? '';
      _selectedColor = widget.vehicle!['color'] ?? 'Black';
      _selectedType = widget.vehicle!['type'] ?? 'car';
      _selectedFuel = widget.vehicle!['fuelType'] ?? 'petrol';
      _insuranceNumberController.text = widget.vehicle!['insuranceNumber'] ?? '';
      _isDefault = widget.vehicle!['isDefault'] ?? false;
      if (widget.vehicle!['insuranceExpiry'] != null) {
        _insuranceExpiry = DateTime.tryParse(widget.vehicle!['insuranceExpiry'].toString());
      }
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _insuranceNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickInsuranceExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _insuranceExpiry ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Sélectionner la date d\'expiration',
    );
    if (date != null) {
      setState(() => _insuranceExpiry = date);
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? result;

      if (widget.vehicle != null) {
        result = await VehicleService.updateVehicle(
          vehicleId: widget.vehicle!['_id'],
          licensePlate: _licensePlateController.text.trim(),
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          year: int.parse(_yearController.text.trim()),
          color: _selectedColor,
          type: _selectedType,
          fuelType: _selectedFuel,
          insuranceNumber: _insuranceNumberController.text.trim(),
          insuranceExpiry: _insuranceExpiry?.toIso8601String(),
        );
      } else {
        result = await VehicleService.createVehicle(
          licensePlate: _licensePlateController.text.trim(),
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          year: int.parse(_yearController.text.trim()),
          color: _selectedColor,
          type: _selectedType,
          fuelType: _selectedFuel,
          insuranceNumber: _insuranceNumberController.text.trim(),
          insuranceExpiry: _insuranceExpiry?.toIso8601String(),
          isDefault: _isDefault,
        );
      }

      if (result != null && mounted) {
        // Check for duplicate plate error
        if (result['code'] == 'DUPLICATE_PLATE' || result['success'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Cette plaque d\'immatriculation existe déjà'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.vehicle != null
                  ? 'Véhicule modifié avec succès'
                  : 'Véhicule ajouté avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la sauvegarde du véhicule'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColor.navy, size: 22),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.navy)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColor.navy)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        elevation: 0,
        title: Text(
          widget.vehicle != null ? 'Modifier le véhicule' : 'Ajouter un véhicule',
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
              // ── Identification ──
              _buildSectionTitle('Identification', Icons.badge),

              _buildLabel('Plaque d\'immatriculation'),
              TextFormField(
                controller: _licensePlateController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Ex: 123 TUN 4567',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true, fillColor: Colors.white,
                  helperText: 'Format: XXX TUN XXXX',
                  prefixIcon: const Icon(Icons.confirmation_number),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'La plaque d\'immatriculation est requise';
                  final regex = RegExp(r'^\d{1,3}\s?TUN\s?\d{1,4}$', caseSensitive: false);
                  if (!regex.hasMatch(value.trim())) return 'Format tunisien requis: XXX TUN XXXX';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Vehicle Details ──
              _buildSectionTitle('Détails du véhicule', Icons.directions_car),

              _buildLabel('Marque'),
              TextFormField(
                controller: _makeController,
                decoration: InputDecoration(
                  hintText: 'Ex: Toyota',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true, fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.branding_watermark),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'La marque est requise' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Modèle'),
              TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  hintText: 'Ex: Corolla',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true, fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.model_training),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Le modèle est requis' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Year
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Année'),
                        TextFormField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Ex: 2020',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true, fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Requise';
                            final year = int.tryParse(value.trim());
                            if (year == null || year < 1900 || year > DateTime.now().year + 1) return 'Année invalide';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Color
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Couleur'),
                        DropdownButtonFormField<String>(
                          value: _selectedColor,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true, fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.palette),
                          ),
                          items: _colors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _selectedColor = v!),
                          validator: (v) => (v == null || v.isEmpty) ? 'Requise' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Type & Fuel ──
              _buildSectionTitle('Type & Carburant', Icons.local_gas_station),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Type de véhicule'),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true, fillColor: Colors.white,
                            prefixIcon: Icon(_typeIcons[_selectedType] ?? Icons.directions_car),
                          ),
                          items: _typeLabels.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedType = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Carburant'),
                        DropdownButtonFormField<String>(
                          value: _selectedFuel,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true, fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.local_gas_station),
                          ),
                          items: _fuelLabels.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedFuel = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Insurance ──
              _buildSectionTitle('Assurance', Icons.security),

              _buildLabel('Numéro d\'assurance (optionnel)'),
              TextFormField(
                controller: _insuranceNumberController,
                decoration: InputDecoration(
                  hintText: 'Ex: ASS-2024-XXXXX',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true, fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.policy),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Date d\'expiration de l\'assurance (optionnel)'),
              InkWell(
                onTap: _pickInsuranceExpiry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.date_range, color: _insuranceExpiry != null ? AppColor.navy : Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _insuranceExpiry != null
                              ? '${_insuranceExpiry!.day}/${_insuranceExpiry!.month}/${_insuranceExpiry!.year}'
                              : 'Sélectionner une date',
                          style: TextStyle(
                            fontSize: 16,
                            color: _insuranceExpiry != null ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                      if (_insuranceExpiry != null)
                        GestureDetector(
                          onTap: () => setState(() => _insuranceExpiry = null),
                          child: const Icon(Icons.close, color: Colors.grey, size: 20),
                        ),
                    ],
                  ),
                ),
              ),

              // Insurance expiry warning
              if (_insuranceExpiry != null && _insuranceExpiry!.difference(DateTime.now()).inDays < 30)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Attention : votre assurance expire dans ${_insuranceExpiry!.difference(DateTime.now()).inDays} jours !',
                          style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ── Default toggle ──
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: const Text('Véhicule par défaut', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Sera automatiquement sélectionné pour vos réservations'),
                  secondary: Icon(Icons.star, color: _isDefault ? AppColor.orange : Colors.grey),
                  value: _isDefault,
                  activeColor: AppColor.orange,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
              ),
              const SizedBox(height: 32),

              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveVehicle,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(
                    widget.vehicle != null ? 'Modifier' : 'Ajouter',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
