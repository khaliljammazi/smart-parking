import 'package:flutter/material.dart';
import '../utils/constanst.dart';

/// Modern bottom sheet for filter options
class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  final Function(Map<String, dynamic>) onApply;

  const FilterBottomSheet({
    super.key,
    this.initialFilters,
    required this.onApply,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic>? initialFilters,
  }) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialFilters: initialFilters,
        onApply: (filters) => Navigator.pop(context, filters),
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  late double _maxDistance;
  late double _minRating;
  late Set<String> _selectedAmenities;
  late bool _showAvailableOnly;

  final List<String> _amenities = [
    'Covered',
    'Security',
    'EV Charging',
    '24/7 Access',
    'Handicap Accessible',
    'Valet',
  ];

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.initialFilters?['minPrice']?.toDouble() ?? 0,
      widget.initialFilters?['maxPrice']?.toDouble() ?? 50,
    );
    _maxDistance = widget.initialFilters?['maxDistance']?.toDouble() ?? 10;
    _minRating = widget.initialFilters?['minRating']?.toDouble() ?? 0;
    _selectedAmenities = Set<String>.from(
      widget.initialFilters?['amenities'] ?? [],
    );
    _showAvailableOnly = widget.initialFilters?['availableOnly'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Price Range
                    _buildSectionTitle('Price Range (DT/hour)', isDark),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      labels: RangeLabels(
                        '${_priceRange.start.round()} DT',
                        '${_priceRange.end.round()} DT',
                      ),
                      activeColor: AppColor.navy,
                      onChanged: (values) {
                        setState(() => _priceRange = values);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_priceRange.start.round()} DT',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                        Text('${_priceRange.end.round()} DT',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Distance
                    _buildSectionTitle('Maximum Distance', isDark),
                    const SizedBox(height: 8),
                    Slider(
                      value: _maxDistance,
                      min: 0.5,
                      max: 50,
                      divisions: 99,
                      label: '${_maxDistance.toStringAsFixed(1)} km',
                      activeColor: AppColor.navy,
                      onChanged: (value) {
                        setState(() => _maxDistance = value);
                      },
                    ),
                    Center(
                      child: Text(
                        '${_maxDistance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rating
                    _buildSectionTitle('Minimum Rating', isDark),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _minRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() => _minRating = (index + 1).toDouble());
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Amenities
                    _buildSectionTitle('Amenities', isDark),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _amenities.map((amenity) {
                        final isSelected = _selectedAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(amenity),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAmenities.add(amenity);
                              } else {
                                _selectedAmenities.remove(amenity);
                              }
                            });
                          },
                          selectedColor: AppColor.navy.withOpacity(0.2),
                          checkmarkColor: AppColor.navy,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColor.navy
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Available Only Toggle
                    SwitchListTile(
                      title: Text(
                        'Show Available Only',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Hide fully occupied parkings',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      value: _showAvailableOnly,
                      activeColor: AppColor.navy,
                      onChanged: (value) {
                        setState(() => _showAvailableOnly = value);
                      },
                    ),
                  ],
                ),
              ),
              // Apply Button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply({
                          'minPrice': _priceRange.start,
                          'maxPrice': _priceRange.end,
                          'maxDistance': _maxDistance,
                          'minRating': _minRating,
                          'amenities': _selectedAmenities.toList(),
                          'availableOnly': _showAvailableOnly,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 50);
      _maxDistance = 10;
      _minRating = 0;
      _selectedAmenities = {};
      _showAvailableOnly = false;
    });
  }
}

/// Sort options bottom sheet
class SortBottomSheet extends StatelessWidget {
  final String? currentSort;
  final Function(String) onSelect;

  const SortBottomSheet({
    super.key,
    this.currentSort,
    required this.onSelect,
  });

  static Future<String?> show(BuildContext context, {String? currentSort}) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SortBottomSheet(
        currentSort: currentSort,
        onSelect: (sort) => Navigator.pop(context, sort),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sortOptions = [
      {'value': 'distance', 'label': 'Distance (Nearest)', 'icon': Icons.near_me},
      {'value': 'price_low', 'label': 'Price (Low to High)', 'icon': Icons.arrow_upward},
      {'value': 'price_high', 'label': 'Price (High to Low)', 'icon': Icons.arrow_downward},
      {'value': 'rating', 'label': 'Rating (Highest)', 'icon': Icons.star},
      {'value': 'availability', 'label': 'Availability', 'icon': Icons.check_circle},
      {'value': 'name', 'label': 'Name (A-Z)', 'icon': Icons.sort_by_alpha},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white30 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.sort,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Sort options
          ...sortOptions.map((option) {
            final isSelected = currentSort == option['value'];
            return ListTile(
              leading: Icon(
                option['icon'] as IconData,
                color: isSelected ? AppColor.navy : (isDark ? Colors.white54 : Colors.black54),
              ),
              title: Text(
                option['label'] as String,
                style: TextStyle(
                  color: isSelected ? AppColor.navy : (isDark ? Colors.white : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColor.navy)
                  : null,
              onTap: () => onSelect(option['value'] as String),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Vehicle selection bottom sheet
class VehicleSelectionSheet extends StatelessWidget {
  final List<Map<String, dynamic>> vehicles;
  final String? selectedVehicleId;
  final Function(Map<String, dynamic>) onSelect;
  final VoidCallback? onAddNew;

  const VehicleSelectionSheet({
    super.key,
    required this.vehicles,
    this.selectedVehicleId,
    required this.onSelect,
    this.onAddNew,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required List<Map<String, dynamic>> vehicles,
    String? selectedVehicleId,
    VoidCallback? onAddNew,
  }) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => VehicleSelectionSheet(
        vehicles: vehicles,
        selectedVehicleId: selectedVehicleId,
        onSelect: (vehicle) => Navigator.pop(context, vehicle),
        onAddNew: onAddNew,
      ),
    );
  }

  IconData _getVehicleIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'truck':
        return Icons.local_shipping;
      case 'bike':
        return Icons.pedal_bike;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white30 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Vehicle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (onAddNew != null)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onAddNew!();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New'),
                  ),
              ],
            ),
          ),
          const Divider(),
          // Vehicle list
          if (vehicles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No vehicles added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          else
            ...vehicles.map((vehicle) {
              final isSelected = selectedVehicleId == vehicle['_id'];
              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColor.navy.withOpacity(0.1)
                        : (isDark ? const Color(0xFF252B48) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getVehicleIcon(vehicle['type']),
                    color: isSelected ? AppColor.navy : (isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
                title: Text(
                  '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  vehicle['licensePlate'] ?? 'No plate',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                trailing: isSelected
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.navy,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Selected',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      )
                    : null,
                onTap: () => onSelect(vehicle),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
