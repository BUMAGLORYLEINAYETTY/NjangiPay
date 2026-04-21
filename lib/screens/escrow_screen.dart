import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/escrow_model.dart';
import '../services/payment_service.dart';

class EscrowScreen extends StatefulWidget {
  const EscrowScreen({super.key});

  @override
  State<EscrowScreen> createState() => _EscrowScreenState();
}

class _EscrowScreenState extends State<EscrowScreen> {
  List<EscrowModel> _escrows = [];
  double _totalHeld = 0;
  bool _isLoading = true;
  final fmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await PaymentService.getEscrowBalance();
    if (result['success']) {
      setState(() {
        _totalHeld = (result['totalHeld'] as num).toDouble();
        _escrows = result['escrows'] as List<EscrowModel>;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _requestEarlyRelease(EscrowModel escrow) async {
    final fee = escrow.remainingHeld * 0.05;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Early Release', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Request early release of XAF ${fmt.format(escrow.remainingHeld)} FCFA?\n\n'
          '5% fee: XAF ${fmt.format(fee)} FCFA\n'
          'You will receive: XAF ${fmt.format(escrow.remainingHeld - fee)} FCFA\n\n'
          'The fee goes to the group\'s insurance fund.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await PaymentService.requestEarlyRelease(escrow.id);
    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['data']['message']), backgroundColor: const Color(0xFF10B981)),
      );
      _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escrow', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Total card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.lock_outline, color: Colors.white, size: 36),
                          const SizedBox(height: 8),
                          Text('Total Held in Escrow',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text('XAF ${fmt.format(_totalHeld)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Releases progressively as you pay on time',
                              style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_escrows.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.lock_open_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No escrow holds',
                                  style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                              Text('Win a cycle to see your payout breakdown here',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      Text('Active Holds',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._escrows.map((e) => _escrowCard(e)),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _escrowCard(EscrowModel e) {
    final groupName = e.group?['name'] ?? 'Group';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: const Icon(Icons.lock, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(groupName,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Won Cycle ${e.cycleWon} • Trust: ${e.trustScoreAtWin}%',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _miniStat('Total Held', 'XAF ${fmt.format(e.totalHeld)}', Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _miniStat('Released', 'XAF ${fmt.format(e.amountReleased)}', const Color(0xFF10B981))),
                const SizedBox(width: 8),
                Expanded(child: _miniStat('Remaining', 'XAF ${fmt.format(e.remainingHeld)}', const Color(0xFFEF4444))),
              ],
            ),
            const SizedBox(height: 16),

            // Release schedule
            Text('Release Schedule',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
            const SizedBox(height: 8),
            ...e.releaseSchedule.map((s) => _scheduleRow(s)),

            const SizedBox(height: 16),

            // Early release button
            if (e.remainingHeld > 0)
              OutlinedButton.icon(
                onPressed: () => _requestEarlyRelease(e),
                icon: const Icon(Icons.flash_on, size: 16),
                label: Text('Request Early Release (5% fee)',
                    style: GoogleFonts.inter(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleRow(ReleaseSlot s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            s.released ? Icons.check_circle : Icons.schedule,
            size: 16,
            color: s.released ? const Color(0xFF10B981) : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cycle ${s.cycleNumber}: XAF ${fmt.format(s.amount)}',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: s.released ? Colors.grey[400] : null,
                  decoration: s.released ? TextDecoration.lineThrough : null),
            ),
          ),
          Text(
            s.released ? 'Released ✓' : 'Pending',
            style: GoogleFonts.inter(
                fontSize: 11,
                color: s.released ? const Color(0xFF10B981) : Colors.orange,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
