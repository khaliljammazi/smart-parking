import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../authentication/auth_service.dart';
import '../utils/constanst.dart';

class AdminVehicleDashboardPage extends StatefulWidget {
  const AdminVehicleDashboardPage({super.key});

  @override
  State<AdminVehicleDashboardPage> createState() =>
      _AdminVehicleDashboardPageState();
}

class _AdminVehicleDashboardPageState extends State<AdminVehicleDashboardPage>
    with SingleTickerProviderStateMixin {
  static const String baseUrl = 'http://localhost:5000/api';
  late TabController _tabController;
  bool _isLoading = true;

  // Vehicles list
  List<dynamic> _vehicles = [];
  int _totalVehicles = 0;
  Map<String, dynamic> _typeCounts = {};
  int _currentPage = 1;
  String _searchQuery = '';
  String? _filterType;

  // Stats
  Map<String, dynamic>? _stats;

  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _typeLabels = {
    'car': 'Voiture',
    'motorcycle': 'Moto',
    'truck': 'Camion',
    'van': 'Fourgon',
    'electric': 'Électrique',
    'hybrid': 'Hybride',
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
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadVehicles(), _loadStats()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadVehicles() async {
    try {
      final headers = await _headers();
      final params = {
        'page': '$_currentPage',
        'limit': '20',
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_filterType != null) 'type': _filterType!,
      };
      final uri = Uri.parse(
        '$baseUrl/admin/vehicles',
      ).replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        if (mounted) {
          setState(() {
            _vehicles = data['vehicles'] ?? [];
            _totalVehicles = data['total'] ?? 0;
            _typeCounts = (data['typeCounts'] as Map<String, dynamic>?) ?? {};
          });
        }
      }
    } catch (e) {
      print('Load vehicles error: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/vehicles/stats'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        if (mounted)
          setState(() => _stats = json.decode(response.body)['data']);
      }
    } catch (e) {
      print('Load stats error: $e');
    }
  }

  Future<void> _verifyVehicle(String vehicleId, bool verified) async {
    try {
      final headers = await _headers();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/vehicles/$vehicleId/verify'),
        headers: headers,
        body: json.encode({'verified': verified}),
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verified ? 'Véhicule vérifié' : 'Véhicule rejeté'),
            backgroundColor: Colors.green,
          ),
        );
        _loadVehicles();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        foregroundColor: Colors.white,
        title: const Text('Gestion des véhicules'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Liste', icon: Icon(Icons.list)),
            Tab(text: 'Statistiques', icon: Icon(Icons.bar_chart)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildVehiclesList(), _buildStatsTab()],
            ),
    );
  }

  // ── Vehicles List Tab ──────────────────────

  Widget _buildVehiclesList() {
    return Column(
      children: [
        // Search + filter bar
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par plaque, marque, modèle...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                            _loadVehicles();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onSubmitted: (v) {
                  setState(() {
                    _searchQuery = v;
                    _currentPage = 1;
                  });
                  _loadVehicles();
                },
              ),
              const SizedBox(height: 8),
              // Type filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tous', null),
                    ..._typeLabels.entries.map(
                      (e) => _buildFilterChip(e.value, e.key),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Total count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '$_totalVehicles véhicule(s)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Page $_currentPage',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadVehicles,
            child: _vehicles.isEmpty
                ? const Center(child: Text('Aucun véhicule trouvé'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _vehicles.length,
                    itemBuilder: (ctx, i) => _buildVehicleCard(_vehicles[i]),
                  ),
          ),
        ),

        // Pagination
        if (_totalVehicles > 20)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() => _currentPage--);
                          _loadVehicles();
                        }
                      : null,
                ),
                Text(
                  '$_currentPage / ${(_totalVehicles / 20).ceil()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < (_totalVehicles / 20).ceil()
                      ? () {
                          setState(() => _currentPage++);
                          _loadVehicles();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? type) {
    final selected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppColor.navy.withOpacity(0.2),
        onSelected: (_) {
          setState(() {
            _filterType = type;
            _currentPage = 1;
          });
          _loadVehicles();
        },
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final owner = vehicle['owner'];
    final ownerName = owner != null
        ? '${owner['firstName'] ?? ''} ${owner['lastName'] ?? ''}'
        : 'Inconnu';
    final ownerEmail = owner?['email'] ?? '';
    final type = vehicle['type'] ?? 'car';
    final isVerified = vehicle['isVerified'] == true;
    final plate = vehicle['licensePlate'] ?? '';
    final make = vehicle['make'] ?? '';
    final model = vehicle['model'] ?? '';
    final year = vehicle['year']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _typeIcons[type] ?? Icons.directions_car,
                  color: AppColor.navy,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plate,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColor.navy,
                        ),
                      ),
                      Text(
                        '$make $model ($year)',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                // Verify badge / buttons
                if (isVerified)
                  const Chip(
                    avatar: Icon(Icons.verified, color: Colors.green, size: 18),
                    label: Text(
                      'Vérifié',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                    backgroundColor: Color(0xFFE8F5E9),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        tooltip: 'Vérifier',
                        onPressed: () => _verifyVehicle(vehicle['_id'], true),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                        ),
                        tooltip: 'Rejeter',
                        onPressed: () => _verifyVehicle(vehicle['_id'], false),
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$ownerName ($ownerEmail)',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
                Chip(
                  label: Text(
                    _typeLabels[type] ?? type,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.grey[200],
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Tab ──────────────────────────────

  Widget _buildStatsTab() {
    if (_stats == null) return const Center(child: Text('Aucune statistique'));

    final typeCounts = (_stats!['typeCounts'] as Map<String, dynamic>?) ?? {};
    final fuelCounts = (_stats!['fuelCounts'] as Map<String, dynamic>?) ?? {};
    final topVehicles = (_stats!['topVehicles'] as List<dynamic>?) ?? [];
    final expiring = (_stats!['expiringInsurance'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _buildStatSummary(
                'Total',
                '${_stats!['totalVehicles'] ?? 0}',
                Icons.directions_car,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatSummary(
                'Vérifiés',
                '${_stats!['verifiedVehicles'] ?? 0}',
                Icons.verified,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Type distribution
          _buildSection(
            'Répartition par type',
            typeCounts.entries.map((e) {
              return ListTile(
                dense: true,
                leading: Icon(
                  _typeIcons[e.key] ?? Icons.directions_car,
                  color: AppColor.navy,
                ),
                title: Text(_typeLabels[e.key] ?? e.key),
                trailing: Text(
                  '${e.value}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Fuel distribution
          _buildSection(
            'Répartition par carburant',
            fuelCounts.entries.map((e) {
              final fuelLabels = {
                'petrol': 'Essence',
                'diesel': 'Diesel',
                'electric': 'Électrique',
                'hybrid': 'Hybride',
                'gas': 'GPL',
              };
              return ListTile(
                dense: true,
                leading: const Icon(
                  Icons.local_gas_station,
                  color: AppColor.orange,
                ),
                title: Text(fuelLabels[e.key] ?? e.key),
                trailing: Text(
                  '${e.value}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Top vehicles by bookings
          if (topVehicles.isNotEmpty)
            _buildSection(
              'Top véhicules par réservations',
              topVehicles.asMap().entries.map((e) {
                final v = e.value;
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: AppColor.orange,
                    radius: 14,
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text(
                    '${v['make'] ?? ''} ${v['model'] ?? ''} (${v['licensePlate'] ?? ''})',
                  ),
                  subtitle: Text(v['ownerName'] ?? ''),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${v['totalBookings'] ?? 0} rés.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(v['totalSpent'] ?? 0).toStringAsFixed(1)} DT',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),

          // Expiring insurance
          if (expiring.isNotEmpty) ...[
            const Text(
              '⚠️ Assurances expirant bientôt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            ...expiring.map((v) {
              final expDate = DateTime.tryParse(
                v['insuranceExpiry']?.toString() ?? '',
              );
              final owner = v['owner'];
              return Card(
                color: Colors.orange[50],
                child: ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  title: Text(
                    '${v['make']} ${v['model']} (${v['licensePlate']})',
                  ),
                  subtitle: Text(
                    '${owner?['firstName'] ?? ''} ${owner?['lastName'] ?? ''} — Expire: ${expDate != null ? '${expDate.day}/${expDate.month}/${expDate.year}' : 'N/A'}',
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatSummary(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}
