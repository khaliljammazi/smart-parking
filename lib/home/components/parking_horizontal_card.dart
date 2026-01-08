import 'package:flutter/material.dart';
import '../../utils/constanst.dart';
import '../../utils/text/regular.dart';
import '../../utils/text/semi_bold.dart';

class ParkingCardHome extends StatelessWidget {
  final String title;
  final String? imagePath;
  final double? rating;
  final double? carPrice;
  final double? motoPrice;
  final String address;
  final bool isFavorite;
  final int id;

  const ParkingCardHome({
    super.key,
    required this.title,
    this.imagePath,
    this.rating,
    this.carPrice,
    this.motoPrice,
    required this.address,
    required this.isFavorite,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              image: DecorationImage(
                image: imagePath != null
                    ? NetworkImage(imagePath!)
                    : const AssetImage('assets/image/home_banner.png') as ImageProvider,
                fit: BoxFit.cover,
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
                      Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 20,
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