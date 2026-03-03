import 'package:flutter/material.dart';
import '../utils/constanst.dart';
import '../authentication/auth_service.dart';
import 'rating_service.dart';
import 'package:intl/intl.dart';

/// Displays other users' reviews for a parking spot
class ParkingReviewsWidget extends StatefulWidget {
  final String parkingId;
  final double currentRating;

  const ParkingReviewsWidget({
    super.key,
    required this.parkingId,
    required this.currentRating,
  });

  @override
  State<ParkingReviewsWidget> createState() => _ParkingReviewsWidgetState();
}

class _ParkingReviewsWidgetState extends State<ParkingReviewsWidget> {
  List<dynamic> _reviews = [];
  List<dynamic> _distribution = [];
  int _totalReviews = 0;
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews({int page = 1}) async {
    if (page == 1) setState(() => _isLoading = true);
    try {
      final data = await RatingService.getParkingRatings(
        widget.parkingId,
        page: page,
        limit: 5,
      );
      if (data != null && mounted) {
        setState(() {
          if (page == 1) {
            _reviews = data['ratings'] ?? [];
          } else {
            _reviews.addAll(data['ratings'] ?? []);
          }
          _distribution = data['distribution'] ?? [];
          final pagination = data['pagination'] ?? {};
          _totalReviews = pagination['total'] ?? 0;
          _totalPages = pagination['pages'] ?? 1;
          _currentPage = page;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _getCountForRating(int star) {
    for (final d in _distribution) {
      if (d['_id'] == star) return d['count'] ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            const Row(
              children: [
                Icon(Icons.reviews, color: AppColor.navy, size: 22),
                SizedBox(width: 8),
                Text(
                  'Avis des utilisateurs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rating summary bar
            if (_totalReviews > 0) ...[
              _buildRatingSummary(),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
            ],

            // Reviews list
            if (_reviews.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Aucun avis pour le moment',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soyez le premier à donner votre avis !',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              ...List.generate(
                _reviews.length,
                (i) => _buildReviewCard(_reviews[i]),
              ),
              if (_currentPage < _totalPages)
                Center(
                  child: TextButton.icon(
                    onPressed: () => _loadReviews(page: _currentPage + 1),
                    icon: const Icon(Icons.expand_more, color: AppColor.navy),
                    label: const Text(
                      'Voir plus d\'avis',
                      style: TextStyle(color: AppColor.navy, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Big rating number
        Column(
          children: [
            Text(
              widget.currentRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < widget.currentRating.round() ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '$_totalReviews avis',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        const SizedBox(width: 24),
        // Distribution bars
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final star = 5 - i;
              final count = _getCountForRating(star);
              final pct = _totalReviews > 0 ? count / _totalReviews : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('$star', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 20,
                      child: Text(
                        '$count',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final user = review['user'] ?? {};
    final firstName = user['firstName']?.toString() ?? '';
    final lastName = user['lastName']?.toString() ?? '';
    final rawAvatar = user['avatar']?.toString();
    // Avatar is stored as relative path like /uploads/avatars/..., need full URL
    final serverUrl = AuthService.baseUrl.replaceAll('/api', '');
    final avatar = (rawAvatar != null && rawAvatar.isNotEmpty)
        ? (rawAvatar.startsWith('http') ? rawAvatar : '$serverUrl$rawAvatar')
        : null;
    final rating = (review['rating'] ?? 0).toDouble();
    final reviewText = review['review']?.toString() ?? '';
    final tags = (review['tags'] as List?)?.cast<String>() ?? [];
    final createdAt = review['createdAt'] != null
        ? DateTime.tryParse(review['createdAt'].toString())
        : null;

    final displayName = '$firstName $lastName'.trim();
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColor.navy.withOpacity(0.15),
                backgroundImage: avatar != null && avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar == null || avatar.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: AppColor.navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName.isNotEmpty ? displayName : 'Utilisateur',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (createdAt != null)
                      Text(
                        DateFormat('dd MMM yyyy', 'fr_FR').format(createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              // Star rating
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          // Review text
          if (reviewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reviewText,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
          ],
          // Tags
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColor.navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: TextStyle(fontSize: 11, color: AppColor.navy.withOpacity(0.8)),
                ),
              )).toList(),
            ),
          ],
          // Admin/Owner reply
          if (review['adminReply'] != null && review['adminReply']['text'] != null) ...[
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
                      Icon(Icons.reply, size: 14, color: AppColor.navy),
                      const SizedBox(width: 4),
                      Text(
                        'Réponse du gestionnaire',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.navy,
                        ),
                      ),
                      const Spacer(),
                      if (review['adminReply']['repliedAt'] != null)
                        Text(
                          DateFormat('dd/MM/yyyy').format(
                            DateTime.parse(review['adminReply']['repliedAt']),
                          ),
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review['adminReply']['text'],
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
