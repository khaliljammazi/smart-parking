import 'package:flutter/material.dart';
import '../utils/constanst.dart';
import '../utils/promo_code_service.dart';

class PromoCodeWidget extends StatefulWidget {
  final String parkingId;
  final double? bookingAmount;
  final Function(Map<String, dynamic> promoData) onPromoApplied;

  const PromoCodeWidget({
    super.key,
    required this.parkingId,
    this.bookingAmount,
    required this.onPromoApplied,
  });

  @override
  State<PromoCodeWidget> createState() => _PromoCodeWidgetState();
}

class _PromoCodeWidgetState extends State<PromoCodeWidget> {
  final _promoController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;
  Map<String, dynamic>? _appliedPromo;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _validatePromoCode() async {
    if (_promoController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Entrez un code promo');
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    final result = await PromoCodeService.validatePromoCode(
      code: _promoController.text.trim().toUpperCase(),
      parkingId: widget.parkingId,
      bookingAmount: widget.bookingAmount,
    );

    if (mounted) {
      setState(() => _isValidating = false);

      if (result != null && result['success'] == true) {
        final promoData = result['data'];
        setState(() => _appliedPromo = promoData);
        widget.onPromoApplied(promoData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code promo "${_promoController.text.toUpperCase()}" appliqué!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result?['message'] ?? 'Code promo invalide ou expiré';
        });
      }
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromo = null;
      _promoController.clear();
      _errorMessage = null;
    });
    widget.onPromoApplied({});
  }

  void _showAvailablePromoCodes() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AvailablePromoCodesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_appliedPromo != null) {
      return _buildAppliedPromoCard();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer, color: AppColor.navy),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Code promo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showAvailablePromoCodes,
                  child: const Text('Voir les codes'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      hintText: 'Entrez le code',
                      border: const OutlineInputBorder(),
                      errorText: _errorMessage,
                      prefixIcon: const Icon(Icons.confirmation_number),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _validatePromoCode(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isValidating ? null : _validatePromoCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: _isValidating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Appliquer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppliedPromoCard() {
    final discountText = PromoCodeService.formatDiscountText(
      discountType: _appliedPromo!['discountType'] ?? 'percentage',
      discountValue: _appliedPromo!['discountValue'] ?? 0,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _promoController.text.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    discountText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: _removePromoCode,
            ),
          ],
        ),
      ),
    );
  }
}

class AvailablePromoCodesSheet extends StatefulWidget {
  const AvailablePromoCodesSheet({super.key});

  @override
  State<AvailablePromoCodesSheet> createState() => _AvailablePromoCodesSheetState();
}

class _AvailablePromoCodesSheetState extends State<AvailablePromoCodesSheet> {
  List<dynamic>? _promoCodes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromoCodes();
  }

  Future<void> _loadPromoCodes() async {
    final codes = await PromoCodeService.getAvailablePromoCodes();
    if (mounted) {
      setState(() {
        _promoCodes = codes ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Codes promo disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_promoCodes == null || _promoCodes!.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Aucun code promo disponible pour le moment'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _promoCodes!.length,
                itemBuilder: (context, index) {
                  final promo = _promoCodes![index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.local_offer, color: AppColor.navy),
                      title: Text(
                        promo['code'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(promo['description'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          // Copy code to clipboard
                          Navigator.pop(context, promo['code']);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
