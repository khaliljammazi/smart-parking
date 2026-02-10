import 'package:flutter/material.dart';
import '../utils/constanst.dart';
import '../utils/text/semi_bold.dart';
import '../utils/text/regular.dart';

class VehicleSelectorWidget extends StatelessWidget {
  final List<dynamic> vehicles;
  final dynamic selectedVehicle;
  final Function(dynamic) onVehicleSelected;
  final VoidCallback onAddVehicle;

  const VehicleSelectorWidget({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleSelected,
    required this.onAddVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SemiBoldText(
                text: 'Select Vehicle for Booking',
                fontSize: 18,
                color: AppColor.forText,
              ),
              IconButton(
                onPressed: onAddVehicle,
                icon: const Icon(Icons.add_circle, color: AppColor.navy),
                tooltip: 'Add New Vehicle',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vehicles.isEmpty)
            _buildEmptyState(context)
          else
            _buildVehicleList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.navyPale,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.navy.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.directions_car,
            size: 48,
            color: AppColor.navy,
          ),
          const SizedBox(height: 12),
          const RegularText(
            text: 'No vehicles added yet',
            fontSize: 14,
            color: AppColor.forText,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAddVehicle,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Vehicle'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList() {
    return Column(
      children: vehicles.map((vehicle) {
        final isSelected = selectedVehicle != null &&
            vehicle['vehicleInforId'] == selectedVehicle['vehicleInforId'];
        
        return _buildVehicleCard(vehicle, isSelected);
      }).toList(),
    );
  }

  Widget _buildVehicleCard(dynamic vehicle, bool isSelected) {
    final String vehicleType = vehicle['trafficName']?.toLowerCase() ?? 'car';
    final IconData vehicleIcon = vehicleType.contains('motor') || vehicleType.contains('moto')
        ? Icons.two_wheeler
        : Icons.directions_car;

    return GestureDetector(
      onTap: () => onVehicleSelected(vehicle),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.navy.withOpacity(0.1) : AppColor.navyPale,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColor.navy : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Vehicle Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColor.navy : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                vehicleIcon,
                color: isSelected ? Colors.white : AppColor.navy,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            
            // Vehicle Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: vehicle['vehicleName'] ?? 'Unknown Vehicle',
                    fontSize: 16,
                    color: AppColor.forText,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SemiBoldText(
                          text: vehicle['licensePlate'] ?? 'N/A',
                          fontSize: 14,
                          color: AppColor.navy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getColorFromString(vehicle['color'] ?? 'gray'),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      const SizedBox(width: 4),
                      RegularText(
                        text: vehicle['color'] ?? 'Unknown',
                        fontSize: 12,
                        color: AppColor.forText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RegularText(
                    text: vehicle['trafficName'] ?? 'Car',
                    fontSize: 12,
                    color: AppColor.fadeText,
                  ),
                ],
              ),
            ),
            
            // Selection Indicator
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColor.navy,
                size: 28,
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromString(String colorName) {
    final colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'black': Colors.black,
      'white': Colors.white,
      'silver': Colors.grey.shade300,
      'gray': Colors.grey,
      'grey': Colors.grey,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'brown': Colors.brown,
      'purple': Colors.purple,
      'pink': Colors.pink,
      // Vietnamese colors
      'đỏ': Colors.red,
      'xanh': Colors.blue,
      'đen': Colors.black,
      'trắng': Colors.white,
      'bạc': Colors.grey.shade300,
      'xám': Colors.grey,
      'vàng': Colors.yellow,
      'cam': Colors.orange,
      'nâu': Colors.brown,
      'tím': Colors.purple,
      'hồng': Colors.pink,
    };

    return colorMap[colorName.toLowerCase()] ?? Colors.grey.shade400;
  }
}
