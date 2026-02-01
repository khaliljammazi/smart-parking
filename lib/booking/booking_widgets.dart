import 'package:flutter/material.dart';
import '../utils/constanst.dart';

/// Step indicator for multi-step booking flow
class BookingStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepTitles;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? completedColor;

  const BookingStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    this.stepTitles,
    this.activeColor,
    this.inactiveColor,
    this.completedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = activeColor ?? AppColor.navy;
    final inactive = inactiveColor ?? (isDark ? Colors.white24 : Colors.grey.shade300);
    final completed = completedColor ?? Colors.green;

    final titles = stepTitles ?? ['Select', 'Details', 'Confirm'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: isCompleted ? completed : inactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          } else {
            // Step circle
            final stepIndex = index ~/ 2;
            final isActive = stepIndex == currentStep;
            final isCompleted = stepIndex < currentStep;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? completed
                        : isActive
                            ? active
                            : inactive,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: active.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black45),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  titles[stepIndex],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }
}

/// Booking summary card for review before confirmation
class BookingSummaryCard extends StatelessWidget {
  final Map<String, dynamic> parkingInfo;
  final Map<String, dynamic> vehicleInfo;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final VoidCallback? onEdit;

  const BookingSummaryCard({
    super.key,
    required this.parkingInfo,
    required this.vehicleInfo,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    this.onEdit,
  });

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '$hours h $minutes min';
    } else if (hours > 0) {
      return '$hours h';
    } else {
      return '$minutes min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration = endTime.difference(startTime);

    return Card(
      elevation: isDark ? 0 : 4,
      color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColor.navy,
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Parking Info
            _buildInfoRow(
              context,
              icon: Icons.local_parking,
              title: 'Parking',
              value: parkingInfo['name'] ?? 'N/A',
              subtitle: parkingInfo['address'],
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Vehicle Info
            _buildInfoRow(
              context,
              icon: Icons.directions_car,
              title: 'Vehicle',
              value: '${vehicleInfo['make'] ?? ''} ${vehicleInfo['model'] ?? ''}',
              subtitle: vehicleInfo['licensePlate'],
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Time Info
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    context,
                    icon: Icons.access_time,
                    title: 'Start',
                    value: _formatDateTime(startTime),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    context,
                    icon: Icons.access_time_filled,
                    title: 'End',
                    value: _formatDateTime(endTime),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Duration
            _buildInfoRow(
              context,
              icon: Icons.timelapse,
              title: 'Duration',
              value: _formatDuration(duration),
              isDark: isDark,
            ),

            const Divider(height: 24),

            // Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Price',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  '${totalPrice.toStringAsFixed(2)} DT',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColor.navy,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColor.navy.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColor.navy, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Booking cancellation bottom sheet
class BookingCancellationSheet extends StatefulWidget {
  final String bookingId;
  final Function(String reason) onCancel;

  const BookingCancellationSheet({
    super.key,
    required this.bookingId,
    required this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String bookingId,
    required Function(String reason) onCancel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingCancellationSheet(
        bookingId: bookingId,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<BookingCancellationSheet> createState() => _BookingCancellationSheetState();
}

class _BookingCancellationSheetState extends State<BookingCancellationSheet> {
  String? _selectedReason;
  final _otherReasonController = TextEditingController();
  bool _isLoading = false;

  final List<String> _reasons = [
    'Change of plans',
    'Found a better option',
    'Vehicle issue',
    'Wrong date/time selected',
    'Price too high',
    'Other',
  ];

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Row(
              children: [
                const Icon(Icons.cancel_outlined, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Cancel Booking',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Please tell us why you want to cancel',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            // Reasons
            ...List.generate(_reasons.length, (index) {
              final reason = _reasons[index];
              final isSelected = _selectedReason == reason;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedReason = reason),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.red.withOpacity(0.1)
                          : (isDark ? const Color(0xFF252B48) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: Colors.red, width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? Colors.red : (isDark ? Colors.white38 : Colors.black38),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          reason,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Other reason text field
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Please specify your reason...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF252B48) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cancellation may be subject to fees depending on the time remaining before your booking.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Keep Booking'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedReason == null || _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            final reason = _selectedReason == 'Other'
                                ? _otherReasonController.text
                                : _selectedReason!;
                            widget.onCancel(reason);
                            if (mounted) {
                              Navigator.pop(context, true);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.red.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Cancel Booking'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
