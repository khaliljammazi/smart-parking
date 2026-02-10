import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constanst.dart';
import '../../utils/text/regular.dart';
import '../../utils/text/semi_bold.dart';
import '../../utils/favorites_provider.dart';

class ParkingCardHome extends StatelessWidget {
  final String title;
  final String? imagePath;
  final double? rating;
  final double? carPrice;
  final double? motoPrice;
  final String address;
  final bool isFavorite;
  final String parkingId; // Changed from int id to String parkingId

  const ParkingCardHome({
    super.key,
    required this.title,
    this.imagePath,
    this.rating,
    this.carPrice,
    this.motoPrice,
    required this.address,
    required this.isFavorite,
    required this.parkingId, // Changed parameter name
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, // Fixed width for horizontal ListView
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Container(
              width: 100,
              height: 100,
              color: Colors.grey[200],
              child: imagePath != null
                  ? Image.network(
                      imagePath!,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/image/home_banner.png',
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
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
                      width: 100,
                      height: 100,
                    ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Favorite
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
                      Consumer<FavoritesProvider>(
                        builder: (context, favProvider, child) {
                          final isFav = favProvider.isFavorite(parkingId);
                          return IconButton(
                            onPressed: () {
                              favProvider.toggleFavorite(parkingId);
                            },
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Rating
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

                  // Prices
                  if (carPrice != null || motoPrice != null)
                    Row(
                      children: [
                        if (carPrice != null)
                          RegularText(
                            text: 'Voiture: ${carPrice!.toStringAsFixed(0)} DT/h',
                            fontSize: 12,
                            color: AppColor.navy,
                          ),
                        if (carPrice != null && motoPrice != null)
                          const SizedBox(width: 8),
                        if (motoPrice != null)
                          RegularText(
                            text: 'Moto: ${motoPrice!.toStringAsFixed(0)} DT/h',
                            fontSize: 12,
                            color: AppColor.orange,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}