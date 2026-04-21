import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String? groupId;
  const PaymentHistoryScreen({super.key, this.groupId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<PaymentModel> _payments = [];
  bool _isLoading = true;
  final fmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _payments = await PaymentService.getPaymentHistory(groupId: widget.groupId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No payments yet', style: GoogleFonts.poppins(color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final p = _payments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showReceipt(p),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: p.isSuccess
                                        ? const Color(0xFF10B981).withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    p.method == 'MTN_MOMO' ? Icons.phone_android : Icons.phone_iphone,
                                    color: p.method == 'MTN_MOMO'
                                        ? const Color(0xFFFFCC00)
                                        : const Color(0xFFFF6600),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.group?['name'] ?? 'Group',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                                      Text(p.methodLabel,
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                                      Text('Cycle ${p.cycleNumber}',
                                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('XAF ${fmt.format(p.amount)}',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: const Color(0xFF1E3A8A))),
                                    Text(DateFormat('MMM d').format(p.createdAt),
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                                    _statusChip(p.status),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showReceipt(PaymentModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Payment Receipt',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _receiptRow('Transaction ID', p.reference.substring(0, 8).toUpperCase()),
            _receiptRow('Date', DateFormat('MMM d, yyyy • h:mm a').format(p.createdAt)),
            _receiptRow('Group', p.group?['name'] ?? 'N/A'),
            _receiptRow('Amount', 'XAF ${fmt.format(p.amount)}'),
            _receiptRow('Method', p.methodLabel),
            _receiptRow('Phone', '+237 ${p.phone}'),
            _receiptRow('Cycle', '#${p.cycleNumber}'),
            const Divider(height: 24),
            _receiptRow('Platform Fee', 'XAF ${fmt.format(p.platformFee)}'),
            _receiptRow('Insurance', 'XAF ${fmt.format(p.insuranceFee)}'),
            _receiptRow('Net to Pot', 'XAF ${fmt.format(p.netAmount)}', highlight: true),
            const Divider(height: 24),
            _receiptRow('Status', p.status),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                  color: highlight ? const Color(0xFF10B981) : null)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final isSuccess = status == 'SUCCESS';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFF10B981).withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isSuccess ? '✓ Paid' : status,
        style: GoogleFonts.inter(
            fontSize: 10,
            color: isSuccess ? const Color(0xFF10B981) : Colors.red,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
