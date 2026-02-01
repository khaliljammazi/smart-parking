import 'package:flutter/material.dart';
import '../model/parking_model.dart';
import '../utils/constanst.dart';
import '../utils/backend_api.dart';
import '../utils/bottom_sheets.dart';
import '../utils/shimmer_loading.dart';
import '../location/map_page.dart';
import 'parking_detail_page.dart';

class ParkingListPage extends StatefulWidget {
  const ParkingListPage({super.key});

  @override
  State<ParkingListPage> createState() => _ParkingListPageState();
}

class _ParkingListPageState extends State<ParkingListPage> {
  List<ParkingModel> _parkings = [];
  List<ParkingModel> _filteredParkings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Map<String, dynamic>? _filters;
  String? _sortBy;
  final _searchController = TextEditingController();
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadParkings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParkings() async {
    setState(() => _isLoading = true);
    try {
      final parkings = await BackendApi.getAllParkingSpots();
      if (mounted) {
        setState(() {
          _parkings = parkings;
          _filteredParkings = parkings;
          _isLoading = false;
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    var result = List<ParkingModel>.from(_parkings);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      result = result.where((p) =>
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.address.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply filters
    if (_filters != null) {
      if (_filters!['minPrice'] != null && _filters!['maxPrice'] != null) {
        result = result.where((p) =>
          p.pricePerHour >= _filters!['minPrice'] &&
          p.pricePerHour <= _filters!['maxPrice']
        ).toList();
      }
      if (_filters!['minRating'] != null && _filters!['minRating'] > 0) {
        result = result.where((p) => p.rating >= _filters!['minRating']).toList();
      }
      if (_filters!['availableOnly'] == true) {
        result = result.where((p) => p.availableSpots > 0).toList();
      }
    }

    // Apply sort
    if (_sortBy != null) {
      switch (_sortBy) {
        case 'price_low':
          result.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
          break;
        case 'price_high':
          result.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
          break;
        case 'rating':
          result.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'availability':
          result.sort((a, b) => b.availableSpots.compareTo(a.availableSpots));
          break;
        case 'name':
          result.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
    }

    setState(() => _filteredParkings = result);
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _applyFiltersAndSort();
    
    // Add to recent searches
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    }
  }

  Future<void> _showFilters() async {
    final result = await FilterBottomSheet.show(
      context,
      initialFilters: _filters,
    );
    if (result != null) {
      setState(() => _filters = result);
      _applyFiltersAndSort();
    }
  }

  Future<void> _showSort() async {
    final result = await SortBottomSheet.show(
      context,
      currentSort: _sortBy,
    );
    if (result != null) {
      setState(() => _sortBy = result);
      _applyFiltersAndSort();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Places de Parking'),
        backgroundColor: isDark ? const Color(0xFF1A1F3A) : AppColor.navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapPage()),
              );
            },
            tooltip: 'Voir sur la carte',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1A1F3A) : AppColor.navy,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search parking...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter & Sort Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showFilters,
                        icon: const Icon(Icons.filter_list, size: 20),
                        label: Text(_filters != null ? 'Filters Active' : 'Filters'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: _filters != null ? Colors.greenAccent : Colors.white54,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showSort,
                        icon: const Icon(Icons.sort, size: 20),
                        label: Text(_sortBy != null ? 'Sorted' : 'Sort'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: _sortBy != null ? Colors.greenAccent : Colors.white54,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Results count
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredParkings.length} résultats',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_filters != null || _sortBy != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filters = null;
                        _sortBy = null;
                      });
                      _applyFiltersAndSort();
                    },
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),
          // Parking List
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) => const SkeletonCard(),
                  )
                : _filteredParkings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: isDark ? Colors.white30 : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No parking found',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadParkings,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filteredParkings.length,
                          itemBuilder: (context, index) {
                            final spot = _filteredParkings[index];
                            return _buildParkingCard(spot, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingCard(ParkingModel spot, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParkingDetailPage(parking: spot),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Parking Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColor.navy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_parking,
                  color: AppColor.navy,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spot.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChip(
                          '${spot.pricePerHour} DT/h',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildChip(
                          '${spot.availableSpots} spots',
                          Icons.local_parking,
                          spot.availableSpots > 0 ? Colors.blue : Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Rating
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          spot.rating.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}