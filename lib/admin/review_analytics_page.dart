import 'package:flutter/material.dart';
import '../utils/constanst.dart';
import 'admin_service.dart';

class ReviewAnalyticsPage extends StatefulWidget {
  const ReviewAnalyticsPage({super.key});

  @override
  State<ReviewAnalyticsPage> createState() => _ReviewAnalyticsPageState();
}

class _ReviewAnalyticsPageState extends State<ReviewAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _analytics;
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingReviews = true;
  int _reviewPage = 1;
  int _totalReviews = 0;
  String _replyFilter = 'all'; // all, unreplied, replied

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final data = await AdminService.getReviewAnalytics();
    if (mounted) {
      setState(() {
        _analytics = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviews({int page = 1}) async {
    setState(() => _isLoadingReviews = true);
    bool? hasReply;
    if (_replyFilter == 'replied') hasReply = true;
    if (_replyFilter == 'unreplied') hasReply = false;

    final data = await AdminService.getAllReviews(
      page: page,
      limit: 20,
      hasReply: hasReply,
    );
    if (mounted && data != null) {
      setState(() {
        _reviews = data['reviews'] ?? [];
        _totalReviews = data['total'] ?? 0;
        _reviewPage = page;
        _isLoadingReviews = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingReviews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytique des avis'),
        backgroundColor: isDark ? const Color(0xFF1A1F3A) : AppColor.navy,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Vue d\'ensemble'),
            Tab(icon: Icon(Icons.trending_up), text: 'Tendances'),
            Tab(icon: Icon(Icons.rate_review), text: 'Avis'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildReviewsTab(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════
  //  TAB 1: OVERVIEW
  // ═══════════════════════════════════════════

  Widget _buildOverviewTab() {
    if (_analytics == null) {
      return const Center(child: Text('Erreur de chargement'));
    }

    final overview = _analytics!['overview'] ?? {};
    final distribution = _analytics!['ratingDistribution'] as List? ?? [];
    final topParkings = _analytics!['topRatedParkings'] as List? ?? [];
    final worstParkings = _analytics!['worstParkings'] as List? ?? [];
    final tagStats = _analytics!['tagStats'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards
          _buildSummaryCards(overview),
          const SizedBox(height: 20),

          // Rating Distribution
          _buildSectionTitle('Distribution des notes', Icons.bar_chart),
          const SizedBox(height: 8),
          _buildDistributionChart(distribution, overview['totalReviews'] ?? 0),
          const SizedBox(height: 24),

          // Top Rated Parkings
          if (topParkings.isNotEmpty) ...[
            _buildSectionTitle('🏆 Meilleurs parkings', Icons.star),
            const SizedBox(height: 8),
            ...topParkings.take(5).map((p) => _buildParkingRankCard(p, isTop: true)),
            const SizedBox(height: 20),
          ],

          // Worst Parkings
          if (worstParkings.isNotEmpty) ...[
            _buildSectionTitle('⚠️ Parkings à améliorer', Icons.warning_amber),
            const SizedBox(height: 8),
            ...worstParkings.take(5).map((p) => _buildParkingRankCard(p, isTop: false)),
            const SizedBox(height: 20),
          ],

          // Tag Patterns
          if (tagStats.isNotEmpty) ...[
            _buildSectionTitle('Tags les plus utilisés', Icons.label),
            const SizedBox(height: 8),
            _buildTagCloud(tagStats),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> overview) {
    final totalReviews = overview['totalReviews'] ?? 0;
    final avgRating = (overview['averageRating'] ?? 0).toDouble();
    final unreplied = overview['unrepliedCount'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '$totalReviews',
            'Total avis',
            Icons.rate_review,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            avgRating.toStringAsFixed(1),
            'Note moyenne',
            Icons.star,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '$unreplied',
            'Sans réponse',
            Icons.reply,
            unreplied > 0 ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart(List distribution, int total) {
    final Map<int, int> counts = {};
    for (final d in distribution) {
      counts[d['_id'] ?? 0] = d['count'] ?? 0;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(5, (i) {
            final star = 5 - i;
            final count = counts[star] ?? 0;
            final pct = total > 0 ? count / total : 0.0;
            final barColor = star >= 4
                ? Colors.green
                : star == 3
                    ? Colors.amber
                    : Colors.red;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Text('$star', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 14,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '$count (${(pct * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildParkingRankCard(dynamic parking, {required bool isTop}) {
    final avg = (parking['avg'] ?? 0).toDouble();
    final count = parking['count'] ?? 0;
    final name = parking['name'] ?? 'N/A';
    final address = parking['address'] ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isTop ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isTop ? Icons.thumb_up : Icons.thumb_down,
            color: isTop ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  avg.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTop ? Colors.green : Colors.red,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.star, size: 16, color: Colors.amber),
              ],
            ),
            Text('$count avis', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildTagCloud(List tagStats) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tagStats.take(15).map((tag) {
            final name = tag['_id'] ?? '';
            final count = tag['count'] ?? 0;
            final avgRating = (tag['avgRating'] ?? 3).toDouble();
            final color = avgRating >= 4
                ? Colors.green
                : avgRating >= 3
                    ? Colors.amber.shade700
                    : Colors.red;

            return Chip(
              label: Text(
                '$name ($count)',
                style: TextStyle(fontSize: 12, color: color),
              ),
              backgroundColor: color.withOpacity(0.1),
              side: BorderSide(color: color.withOpacity(0.3)),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  TAB 2: TRENDS
  // ═══════════════════════════════════════════

  Widget _buildTrendsTab() {
    final monthlyTrend = _analytics?['monthlyTrend'] as List? ?? [];
    final complaints = _analytics?['recentComplaints'] as List? ?? [];

    if (monthlyTrend.isEmpty && complaints.isEmpty) {
      return const Center(child: Text('Pas assez de données'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Monthly trend table
        if (monthlyTrend.isNotEmpty) ...[
          _buildSectionTitle('Évolution mensuelle', Icons.timeline),
          const SizedBox(height: 8),
          _buildMonthlyTrendTable(monthlyTrend),
          const SizedBox(height: 24),
        ],

        // Recent complaints
        if (complaints.isNotEmpty) ...[
          _buildSectionTitle('Réclamations récentes (≤ 2★)', Icons.warning),
          const SizedBox(height: 8),
          ...complaints.map((c) => _buildComplaintCard(c)),
        ],
      ],
    );
  }

  Widget _buildMonthlyTrendTable(List trend) {
    final months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header
            Row(
              children: const [
                Expanded(flex: 2, child: Text('Mois', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('Avis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text('Moy.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text('😊', style: TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text('😞', style: TextStyle(fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
            const Divider(),
            ...trend.map((t) {
              final id = t['_id'] ?? {};
              final month = months[id['month'] ?? 0];
              final year = id['year'] ?? 0;
              final count = t['count'] ?? 0;
              final avg = (t['avgRating'] ?? 0).toDouble();
              final high = t['highCount'] ?? 0;
              final low = t['lowCount'] ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('$month $year', style: const TextStyle(fontSize: 13))),
                    Expanded(child: Text('$count', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                    Expanded(
                      child: Text(
                        avg.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: avg >= 4 ? Colors.green : avg >= 3 ? Colors.amber.shade700 : Colors.red,
                        ),
                      ),
                    ),
                    Expanded(child: Text('$high', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.green))),
                    Expanded(child: Text('$low', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.red))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(dynamic complaint) {
    final user = complaint['user'] ?? {};
    final parking = complaint['parking'] ?? {};
    final rating = complaint['rating'] ?? 0;
    final review = complaint['review'] ?? '';
    final tags = (complaint['tags'] as List?)?.cast<String>() ?? [];
    final createdAt = complaint['createdAt'] != null
        ? DateTime.tryParse(complaint['createdAt'].toString())
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(5, (i) => Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: Colors.red.shade400,
                )),
                const Spacer(),
                if (createdAt != null)
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${parking['name'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              'Par ${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (review.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review, style: const TextStyle(fontSize: 13, height: 1.4)),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: tags.map((t) => Chip(
                  label: Text(t, style: const TextStyle(fontSize: 10)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  TAB 3: ALL REVIEWS (with reply)
  // ═══════════════════════════════════════════

  Widget _buildReviewsTab() {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('Tous', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Sans réponse', 'unreplied'),
              const SizedBox(width: 8),
              _buildFilterChip('Avec réponse', 'replied'),
            ],
          ),
        ),
        // Total
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '$_totalReviews avis',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => _loadReviews(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingReviews
              ? const Center(child: CircularProgressIndicator())
              : _reviews.isEmpty
                  ? const Center(child: Text('Aucun avis trouvé'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _reviews.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _reviews.length) {
                          if (_reviews.length < _totalReviews) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: ElevatedButton(
                                onPressed: () => _loadReviews(page: _reviewPage + 1),
                                child: const Text('Charger plus'),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        return _buildAdminReviewCard(_reviews[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _replyFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
      selected: isSelected,
      selectedColor: AppColor.navy,
      onSelected: (_) {
        setState(() => _replyFilter = value);
        _loadReviews();
      },
    );
  }

  Widget _buildAdminReviewCard(dynamic review) {
    final user = review['user'] ?? {};
    final parking = review['parking'] ?? {};
    final rating = (review['rating'] ?? 0).toDouble();
    final reviewText = review['review']?.toString() ?? '';
    final adminReply = review['adminReply'];
    final hasReply = adminReply != null && adminReply['text'] != null;
    final reviewId = review['_id']?.toString() ?? '';
    final createdAt = review['createdAt'] != null
        ? DateTime.tryParse(review['createdAt'].toString())
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColor.navy.withOpacity(0.1),
                  child: Text(
                    '${(user['firstName'] ?? 'U')[0]}',
                    style: const TextStyle(color: AppColor.navy, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        parking['name'] ?? 'N/A',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) => Icon(
                        i < rating.round() ? Icons.star : Icons.star_border,
                        size: 14,
                        color: Colors.amber,
                      )),
                    ),
                    if (createdAt != null)
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ],
            ),

            // Review text
            if (reviewText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(reviewText, style: const TextStyle(fontSize: 13, height: 1.4)),
            ],

            // Existing admin reply
            if (hasReply) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: AppColor.navy, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply, size: 14, color: AppColor.navy),
                        const SizedBox(width: 4),
                        const Text(
                          'Réponse publiée',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.navy),
                        ),
                        const Spacer(),
                        if (adminReply['repliedBy'] != null)
                          Text(
                            '${adminReply['repliedBy']['firstName'] ?? ''} ${adminReply['repliedBy']['lastName'] ?? ''}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      adminReply['text'],
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!hasReply)
                  TextButton.icon(
                    onPressed: () => _showReplyDialog(reviewId),
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Répondre', style: TextStyle(fontSize: 12)),
                  ),
                if (hasReply)
                  TextButton.icon(
                    onPressed: () => _showReplyDialog(reviewId, existingReply: adminReply['text']),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                  ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(reviewId),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Supprimer', style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReplyDialog(String reviewId, {String? existingReply}) async {
    final controller = TextEditingController(text: existingReply);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Répondre à l\'avis'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Votre réponse publique...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.navy),
            child: const Text('Publier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.trim().length >= 2) {
      final success = await AdminService.replyToReview(reviewId, result.trim());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réponse publiée avec succès'), backgroundColor: Colors.green),
        );
        _loadReviews(page: _reviewPage);
      }
    }
  }

  Future<void> _confirmDelete(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'avis'),
        content: const Text('Voulez-vous vraiment supprimer cet avis ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AdminService.deleteReview(reviewId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avis supprimé'), backgroundColor: Colors.green),
        );
        _loadReviews(page: _reviewPage);
        _loadAnalytics(); // Refresh stats
      }
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColor.navy),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
