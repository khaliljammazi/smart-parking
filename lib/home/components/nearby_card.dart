import 'package:flutter/material.dart';
import '../../utils/constanst.dart';
import '../../utils/text/regular.dart';
import '../../utils/text/semi_bold.dart';

class NearByCard extends StatelessWidget {
  final int id;
  final String title;
  final String? imagePath;
  final double? rating;
  final double? carPrice;
  final double? motoPrice;
  final String address;
  final bool isPrepayment;
  final bool isOvernight;
  final double distance;

  const NearByCard({
    super.key,
    required this.id,
    required this.title,
    this.imagePath,
    this.rating,
    this.carPrice,
    this.motoPrice,
    required this.address,
    required this.isPrepayment,
    required this.isOvernight,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              height: 140,
              color: Colors.grey[200],
              child: imagePath != null
                  ? Image.network(
                      imagePath!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/image/home_banner.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      'assets/image/home_banner.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SemiBoldText(
                        text: title,
                        fontSize: 16,
                        color: AppColor.forText,
                        maxLine: 1,
                      ),
                    ),
                    if (rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          RegularText(
                            text: rating!.toStringAsFixed(1),
                            fontSize: 14,
                            color: AppColor.forText,
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                // Address
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColor.navy, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: RegularText(
                        text: address,
                        fontSize: 12,
                        color: AppColor.forText,
                        maxLine: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Distance
                RegularText(
                  text: '${distance.toStringAsFixed(1)} km',
                  fontSize: 12,
                  color: AppColor.navy,
                ),

                const SizedBox(height: 8),

                // Prices
                if (carPrice != null || motoPrice != null)
                  Row(
                    children: [
                      if (carPrice != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColor.navy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: RegularText(
                            text: '${carPrice!.toStringAsFixed(0)} DT/h',
                            fontSize: 12,
                            color: AppColor.navy,
                          ),
                        ),
                      if (carPrice != null && motoPrice != null)
                        const SizedBox(width: 8),
                      if (motoPrice != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColor.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: RegularText(
                            text: '${motoPrice!.toStringAsFixed(0)} DT/h',
                            fontSize: 12,
                            color: AppColor.orange,
                          ),
                        ),
                    ],
                  ),

                const SizedBox(height: 8),

                // Features
                Row(
                  children: [
                    if (isPrepayment)
                      _buildFeatureChip('Paiement anticipé', AppColor.navy),
                    if (isPrepayment && isOvernight)
                      const SizedBox(width: 8),
                    if (isOvernight)
                      _buildFeatureChip('Nuit', AppColor.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: RegularText(
        text: text,
        fontSize: 10,
        color: color,
      ),
    );
  }
}