import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constanst.dart';
import '../utils/text/semi_bold.dart';
import '../utils/text/regular.dart';
import '../utils/text/medium.dart';
import '../vehicle/vehicle_provider.dart';
import '../vehicle/vehicle_form_page.dart';
import 'vehicle_selector_widget.dart';
import 'booking_service.dart';
import 'package:intl/intl.dart';

/// Enhanced booking confirmation page with multiple vehicle selection
class EnhancedBookingConfirmationPage extends StatefulWidget {
  final String parkingName;
  final String parkingAddress;
  final String floorName;
  final String slotName;
  final DateTime startTime;
  final DateTime endTime;
  final int duration;
  final double estimatedPrice;
  final int parkingSlotId;
  final int parkingId;

  const EnhancedBookingConfirmationPage({
    super.key,
    required this.parkingName,
    required this.parkingAddress,
    required this.floorName,
    required this.slotName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.estimatedPrice,
    required this.parkingSlotId,
    required this.parkingId,
  });

  @override
  State<EnhancedBookingConfirmationPage> createState() =>
      _EnhancedBookingConfirmationPageState();
}

class _EnhancedBookingConfirmationPageState
    extends State<EnhancedBookingConfirmationPage> {
  int _selectedPaymentMethod = 1; // 0: Prepay, 1: Postpay
  String? _guestName;
  String? _guestPhone;

  // Smart pricing
  Map<String, dynamic>? _smartPrice;
  bool _loadingPrice = false;

  // Recurring booking
  bool _isRecurring = false;
  String _recurringPattern = 'weekdays';
  List<int> _selectedDays = [];
  DateTime? _recurringUntil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadVehicles();
      _fetchSmartPrice();
    });
  }

  Future<void> _fetchSmartPrice() async {
    setState(() => _loadingPrice = true);
    final result = await BookingService.calculateSmartPrice(
      parkingId: widget.parkingId.toString(),
      startTime: widget.startTime.toIso8601String(),
      endTime: widget.endTime.toIso8601String(),
    );
    if (mounted) {
      setState(() {
        _smartPrice = result;
        _loadingPrice = false;
      });
    }
  }

  void _showGuestBookingDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const SemiBoldText(
          text: 'Book for Guest',
          fontSize: 20,
          color: AppColor.forText,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Guest Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Guest Phone',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _guestName = nameController.text;
                _guestPhone = phoneController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmBooking() {
    final vehicleProvider = context.read<VehicleProvider>();
    
    if (vehicleProvider.selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle for this booking'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Call booking API with selected vehicle
    final selectedVehicleId = vehicleProvider.selectedVehicle['vehicleInforId'];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking with vehicle ID: $selectedVehicleId'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back or to booking confirmation page
    // Navigator.push(context, MaterialPageRoute(builder: (context) => BookingSuccessPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.navyPale,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: AppColor.forText),
        title: const SemiBoldText(
          text: 'Confirm Booking',
          fontSize: 20,
          color: AppColor.forText,
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildParkingInfoCard(),
            const SizedBox(height: 12),
            _buildTimeInfoCard(),
            const SizedBox(height: 12),
            _buildSmartPricingCard(),
            const SizedBox(height: 12),
            _buildBookerInfoCard(),
            const SizedBox(height: 12),
            _buildVehicleSelectionCard(),
            const SizedBox(height: 12),
            _buildRecurringCard(),
            const SizedBox(height: 12),
            _buildPaymentMethodCard(),
            const SizedBox(height: 12),
            _buildPriceSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildParkingInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Parking Location',
            fontSize: 18,
            color: AppColor.forText,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColor.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: widget.parkingName,
                      fontSize: 16,
                      color: AppColor.forText,
                    ),
                    RegularText(
                      text: widget.parkingAddress,
                      fontSize: 12,
                      color: AppColor.fadeText,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const MediumText(
                text: 'Parking Spot',
                fontSize: 14,
                color: AppColor.forText,
              ),
              SemiBoldText(
                text: '${widget.floorName} - ${widget.slotName}',
                fontSize: 14,
                color: AppColor.navy,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Booking Time',
            fontSize: 18,
            color: AppColor.forText,
          ),
          const SizedBox(height: 12),
          _buildTimeRow('Check-in', widget.startTime),
          const SizedBox(height: 8),
          _buildTimeRow('Check-out', widget.endTime),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const MediumText(
                text: 'Duration',
                fontSize: 14,
                color: AppColor.forText,
              ),
              SemiBoldText(
                text: '${widget.duration} hours',
                fontSize: 14,
                color: AppColor.navy,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MediumText(text: label, fontSize: 14, color: AppColor.forText),
        SemiBoldText(
          text:
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - ${time.day}/${time.month}/${time.year}',
          fontSize: 14,
          color: AppColor.forText,
        ),
      ],
    );
  }

  Widget _buildBookerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SemiBoldText(
                text: 'Booker Information',
                fontSize: 18,
                color: AppColor.forText,
              ),
              TextButton(
                onPressed: _showGuestBookingDialog,
                child: const Text('Book for Guest'),
              ),
            ],
          ),
          if (_guestName != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Name', _guestName!),
            const SizedBox(height: 8),
            _buildInfoRow('Phone', _guestPhone ?? 'N/A'),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleSelectionCard() {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        if (vehicleProvider.isLoading) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return VehicleSelectorWidget(
          vehicles: vehicleProvider.vehicles,
          selectedVehicle: vehicleProvider.selectedVehicle,
          onVehicleSelected: (vehicle) {
            vehicleProvider.selectVehicle(vehicle);
          },
          onAddVehicle: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VehicleFormPage(),
              ),
            );
            if (result == true) {
              vehicleProvider.loadVehicles();
            }
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Payment Method',
            fontSize: 18,
            color: AppColor.forText,
          ),
          RadioListTile<int>(
            contentPadding: EdgeInsets.zero,
            title: const MediumText(
              text: 'Pay Later (at parking)',
              fontSize: 15,
              color: AppColor.forText,
            ),
            value: 1,
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() => _selectedPaymentMethod = value!);
            },
          ),
          RadioListTile<int>(
            contentPadding: EdgeInsets.zero,
            title: const MediumText(
              text: 'Pay Now (prepayment)',
              fontSize: 15,
              color: AppColor.forText,
            ),
            value: 0,
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() => _selectedPaymentMethod = value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryCard() {
    final total = _smartPrice != null ? _smartPrice!['total'] : widget.estimatedPrice;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const MediumText(
                text: 'Estimated Price',
                fontSize: 16,
                color: AppColor.forText,
              ),
              _loadingPrice
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : SemiBoldText(
                      text: '${(total is num ? total : widget.estimatedPrice).toStringAsFixed(2)} DT',
                      fontSize: 20,
                      color: AppColor.orange,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  /// Smart pricing info card
  Widget _buildSmartPricingCard() {
    if (_loadingPrice) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_smartPrice == null || _smartPrice!['smartPricingEnabled'] != true) {
      return const SizedBox.shrink();
    }

    final isPeak = _smartPrice!['isPeak'] == true;
    final discountType = _smartPrice!['discountType'] ?? 'none';
    final discount = (_smartPrice!['discount'] ?? 0).toDouble();
    final baseRate = (_smartPrice!['baseRate'] ?? 0).toDouble();
    final appliedRate = (_smartPrice!['appliedRate'] ?? 0).toDouble();

    Color tagColor;
    IconData tagIcon;
    String tagLabel;

    if (isPeak) {
      tagColor = Colors.red;
      tagIcon = Icons.trending_up;
      tagLabel = 'Heures de pointe (x${_smartPrice!['peakMultiplier']})';
    } else if (discountType == 'off_peak') {
      tagColor = Colors.green;
      tagIcon = Icons.trending_down;
      tagLabel = 'Hors pointe — ${discount.toStringAsFixed(0)}% de réduction';
    } else if (discountType == 'long_stay') {
      tagColor = Colors.teal;
      tagIcon = Icons.access_time_filled;
      tagLabel = 'Longue durée — ${discount.toStringAsFixed(0)}% de réduction';
    } else {
      tagColor = Colors.grey;
      tagIcon = Icons.info_outline;
      tagLabel = 'Tarif standard';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tagColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.price_change, size: 20, color: tagColor),
              const SizedBox(width: 8),
              const SemiBoldText(text: 'Smart Pricing', fontSize: 16, color: AppColor.forText),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tagIcon, size: 16, color: tagColor),
                const SizedBox(width: 6),
                Text(tagLabel, style: TextStyle(color: tagColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const MediumText(text: 'Tarif de base', fontSize: 13, color: AppColor.fadeText),
              Text('${baseRate.toStringAsFixed(2)} DT/h',
                  style: TextStyle(fontSize: 13, color: AppColor.fadeText,
                      decoration: isPeak || discountType != 'none' ? TextDecoration.lineThrough : null)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const MediumText(text: 'Tarif appliqué', fontSize: 14, color: AppColor.forText),
              SemiBoldText(text: '${appliedRate.toStringAsFixed(2)} DT/h', fontSize: 14, color: tagColor),
            ],
          ),
        ],
      ),
    );
  }

  /// Recurring booking card
  Widget _buildRecurringCard() {
    final dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SemiBoldText(text: 'Réservation récurrente', fontSize: 16, color: AppColor.forText),
              Switch(
                value: _isRecurring,
                activeColor: AppColor.navy,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
            ],
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 12),
            // Pattern selector
            DropdownButtonFormField<String>(
              value: _recurringPattern,
              decoration: const InputDecoration(
                labelText: 'Fréquence',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Tous les jours')),
                DropdownMenuItem(value: 'weekdays', child: Text('Jours ouvrables (Lun-Ven)')),
                DropdownMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
                DropdownMenuItem(value: 'monthly', child: Text('Mensuel')),
              ],
              onChanged: (v) => setState(() => _recurringPattern = v!),
            ),
            // Day-of-week chips for weekly
            if (_recurringPattern == 'weekly') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final selected = _selectedDays.contains(i);
                  return FilterChip(
                    label: Text(dayNames[i]),
                    selected: selected,
                    selectedColor: AppColor.navy.withOpacity(0.2),
                    onSelected: (s) {
                      setState(() {
                        if (s) {
                          _selectedDays.add(i);
                        } else {
                          _selectedDays.remove(i);
                        }
                      });
                    },
                  );
                }),
              ),
            ],
            const SizedBox(height: 12),
            // Valid until
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _recurringUntil ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _recurringUntil = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Valable jusqu\'au',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: Text(
                  _recurringUntil != null
                      ? DateFormat('dd/MM/yyyy').format(_recurringUntil!)
                      : '30 jours par défaut',
                  style: TextStyle(
                    color: _recurringUntil != null ? AppColor.forText : AppColor.fadeText,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _confirmBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.navy,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const SemiBoldText(
          text: 'Confirm Booking',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MediumText(text: label, fontSize: 14, color: AppColor.forText),
        SemiBoldText(text: value, fontSize: 14, color: AppColor.forText),
      ],
    );
  }
}
