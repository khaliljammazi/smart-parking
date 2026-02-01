import 'package:flutter/material.dart';

/// Shimmer effect for loading skeletons
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  
  const ShimmerLoading({required this.child, super.key});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF252B48),
                      const Color(0xFF3D4466),
                      const Color(0xFF252B48),
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton placeholder box
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  
  const SkeletonBox({
    this.width,
    required this.height,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Skeleton for parking list cards
class ParkingCardSkeleton extends StatelessWidget {
  const ParkingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image placeholder
              SkeletonBox(
                width: 100,
                height: 80,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: double.infinity, height: 20),
                    const SizedBox(height: 8),
                    SkeletonBox(width: 150, height: 14),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SkeletonBox(width: 60, height: 14),
                        const SizedBox(width: 16),
                        SkeletonBox(width: 80, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton list for multiple parking cards
class ParkingListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ParkingListSkeleton({this.itemCount = 5, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ParkingCardSkeleton(),
    );
  }
}

/// Skeleton for booking history cards
class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 180, height: 20),
                  SkeletonBox(
                    width: 80,
                    height: 28,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Location
              SkeletonBox(width: 220, height: 14),
              const SizedBox(height: 12),
              // Date and time
              Row(
                children: [
                  SkeletonBox(width: 24, height: 24, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(width: 8),
                  SkeletonBox(width: 120, height: 14),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SkeletonBox(width: 24, height: 24, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(width: 8),
                  SkeletonBox(width: 100, height: 14),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(child: SkeletonBox(height: 40, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(width: 12),
                  Expanded(child: SkeletonBox(height: 40, borderRadius: BorderRadius.circular(8))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton list for booking history
class BookingListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const BookingListSkeleton({this.itemCount = 4, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) => const BookingCardSkeleton(),
    );
  }
}

/// Skeleton for vehicle list items
class VehicleCardSkeleton extends StatelessWidget {
  const VehicleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: SkeletonBox(
            width: 50,
            height: 50,
            borderRadius: BorderRadius.circular(25),
          ),
          title: SkeletonBox(width: 150, height: 18),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              SkeletonBox(width: 100, height: 14),
            ],
          ),
          trailing: SkeletonBox(width: 70, height: 30, borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

/// Skeleton for dashboard stats cards
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  SkeletonBox(width: 60, height: 24),
                ],
              ),
              const SizedBox(height: 16),
              SkeletonBox(width: 80, height: 14),
              const SizedBox(height: 8),
              SkeletonBox(width: 120, height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid of stat card skeletons
class StatGridSkeleton extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  
  const StatGridSkeleton({
    this.crossAxisCount = 2,
    this.itemCount = 4,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const StatCardSkeleton(),
    );
  }
}

/// Skeleton for notification items
class NotificationItemSkeleton extends StatelessWidget {
  const NotificationItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SkeletonBox(
          width: 48,
          height: 48,
          borderRadius: BorderRadius.circular(24),
        ),
        title: SkeletonBox(width: 200, height: 16),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            SkeletonBox(width: 280, height: 14),
            const SizedBox(height: 4),
            SkeletonBox(width: 80, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Full screen skeleton with custom message
class FullScreenSkeleton extends StatelessWidget {
  final String? message;
  
  const FullScreenSkeleton({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton for profile header
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          SkeletonBox(
            width: 100,
            height: 100,
            borderRadius: BorderRadius.circular(50),
          ),
          const SizedBox(height: 16),
          SkeletonBox(width: 150, height: 24),
          const SizedBox(height: 8),
          SkeletonBox(width: 200, height: 16),
        ],
      ),
    );
  }
}
