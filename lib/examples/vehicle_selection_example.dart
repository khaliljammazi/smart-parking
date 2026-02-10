import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vehicle/vehicle_provider.dart';
import '../booking/vehicle_selector_widget.dart';
import '../vehicle/vehicle_form_page.dart';

/// Example page demonstrating multiple vehicle selection
/// This shows how to use VehicleProvider and VehicleSelectorWidget
class VehicleSelectionExample extends StatefulWidget {
  const VehicleSelectionExample({super.key});

  @override
  State<VehicleSelectionExample> createState() => _VehicleSelectionExampleState();
}

class _VehicleSelectionExampleState extends State<VehicleSelectionExample> {
  @override
  void initState() {
    super.initState();
    // Load vehicles when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadVehicles();
    });
  }

  void _showSelectedVehicleInfo() {
    final vehicleProvider = context.read<VehicleProvider>();
    final selected = vehicleProvider.selectedVehicle;

    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vehicle selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selected Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${selected['vehicleInforId']}'),
            Text('Name: ${selected['vehicleName']}'),
            Text('License: ${selected['licensePlate']}'),
            Text('Color: ${selected['color']}'),
            Text('Type: ${selected['trafficName']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _filterVehicles(String type) {
    final vehicleProvider = context.read<VehicleProvider>();
    final filtered = vehicleProvider.getVehiclesByType(type);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type Vehicles'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final vehicle = filtered[index];
              return ListTile(
                leading: Icon(
                  type.toLowerCase() == 'car'
                      ? Icons.directions_car
                      : Icons.two_wheeler,
                ),
                title: Text(vehicle['vehicleName']),
                subtitle: Text(vehicle['licensePlate']),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Selection Example'),
        actions: [
          // Show vehicle count
          Consumer<VehicleProvider>(
            builder: (context, provider, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${provider.vehicleCount} vehicles',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Example 1: Basic vehicle selector
            const Text(
              'Example 1: Vehicle Selector Widget',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<VehicleProvider>(
              builder: (context, vehicleProvider, child) {
                if (vehicleProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return VehicleSelectorWidget(
                  vehicles: vehicleProvider.vehicles,
                  selectedVehicle: vehicleProvider.selectedVehicle,
                  onVehicleSelected: (vehicle) {
                    vehicleProvider.selectVehicle(vehicle);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Selected: ${vehicle['vehicleName']}',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onAddVehicle: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehicleFormPage(),
                      ),
                    );
                    if (result == true) {
                      vehicleProvider.loadVehicles();
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Example 2: Action buttons
            const Text(
              'Example 2: Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _showSelectedVehicleInfo,
                  icon: const Icon(Icons.info),
                  label: const Text('Show Selected'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<VehicleProvider>().clearSelection();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selection cleared'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Selection'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _filterVehicles('car'),
                  icon: const Icon(Icons.directions_car),
                  label: const Text('Filter Cars'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _filterVehicles('motorcycle'),
                  icon: const Icon(Icons.two_wheeler),
                  label: const Text('Filter Motorcycles'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Example 3: Vehicle stats
            const Text(
              'Example 3: Vehicle Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<VehicleProvider>(
              builder: (context, provider, child) {
                final cars = provider.getVehiclesByType('car');
                final motorcycles = provider.getVehiclesByType('motorcycle');

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatRow('Total Vehicles', provider.vehicleCount),
                        _buildStatRow('Cars', cars.length),
                        _buildStatRow('Motorcycles', motorcycles.length),
                        const Divider(),
                        _buildStatRow(
                          'Selected',
                          provider.selectedVehicle != null ? 1 : 0,
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Example 4: Simple dropdown selector
            const Text(
              'Example 4: Dropdown Selector',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<VehicleProvider>(
              builder: (context, provider, child) {
                if (provider.vehicles.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No vehicles to display'),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<dynamic>(
                      value: provider.selectedVehicle,
                      decoration: const InputDecoration(
                        labelText: 'Quick Select Vehicle',
                        border: OutlineInputBorder(),
                      ),
                      items: provider.vehicles.map((vehicle) {
                        return DropdownMenuItem(
                          value: vehicle,
                          child: Row(
                            children: [
                              Icon(
                                (vehicle['trafficName'] ?? '')
                                        .toLowerCase()
                                        .contains('motor')
                                    ? Icons.two_wheeler
                                    : Icons.directions_car,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${vehicle['vehicleName']} (${vehicle['licensePlate']})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (vehicle) {
                        provider.selectVehicle(vehicle);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
