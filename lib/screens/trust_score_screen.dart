import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/trust_model.dart';
import '../services/payment_service.dart';

class TrustScoreScreen extends StatefulWidget {
  const TrustScoreScreen({super.key});

  @override
  State<TrustScoreScreen> createState() => _TrustScoreScreenState();
}

class _TrustScoreScreenState extends State<TrustScoreScreen> {
  TrustScoreModel? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _data = await PaymentService.getTrustScore();
    setState(() => _isLoading = false);
  }

  Color _scoreColor(int score) {
    if (score >= 90) return const Color(0xFF10B981);
    if (score >= 70) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trust Score', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Failed to load'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _scoreCircle(),
                        const SizedBox(height: 24),
                        _payoutCard(),
                        const SizedBox(height: 20),
                        _progressCard(),
                        const SizedBox(height: 20),
                        _tipsCard(),
                        const SizedBox(height: 20),
                        _historySection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _scoreCircle() {
    final score = _data!.currentScore;
    final color = _scoreColor(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                children: [
                  Text('$score', style: GoogleFonts.poppins(fontSize: 42, fontWeight: FontWeight.bold, color: color)),
                  Text('/ 100', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            score >= 90 ? '⭐ Excellent' : score >= 70 ? '✅ Good' : '⚠️ Needs Improvement',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text('Your payout tier is ${_data!.payoutBreakdown.nowPercent}% now / ${_data!.payoutBreakdown.heldPercent}% held',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _payoutCard() {
    final b = _data!.payoutBreakdown;
    final fmt = NumberFormat('#,##0', 'en_US');
    const examplePot = 125000.0;
    final nowEx = examplePot * b.nowPercent / 100;
    final heldEx = examplePot - nowEx;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Payout Breakdown',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Example with 125,000 FCFA pot',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 14),
            _splitBar(b.nowPercent, b.heldPercent),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _infoBox('Now', '${b.nowPercent}%\nXAF ${fmt.format(nowEx)}', const Color(0xFF10B981))),
                const SizedBox(width: 10),
                Expanded(child: _infoBox('Held', '${b.heldPercent}%\nXAF ${fmt.format(heldEx)}', Colors.orange)),
              ],
            ),
            if (b.releaseCycles > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Held amount releases over ${b.releaseCycles} cycle(s) as you pay on time.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _splitBar(int now, int held) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          if (now > 0)
            Expanded(
              flex: now,
              child: Container(
                height: 12,
                color: const Color(0xFF10B981),
              ),
            ),
          if (held > 0)
            Expanded(
              flex: held,
              child: Container(
                height: 12,
                color: Colors.orange,
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final score = _data!.currentScore;
    final nextTier = _data!.nextTier;
    final points = _data!.pointsToNextTier;
    final color = _scoreColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress to Next Tier ($nextTier)',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: score / nextTier,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text('$points more point${points == 1 ? '' : 's'} to reach $nextTier% tier',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _tipsCard() {
    return Card(
      child: ExpansionTile(
        title: Text('How to Improve', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const Icon(Icons.trending_up, color: Color(0xFF10B981)),
        children: [
          ..._data!.improvements.map((i) => ListTile(
                dense: true,
                leading: const Icon(Icons.add_circle, color: Color(0xFF10B981), size: 18),
                title: Text(i['action'] ?? '', style: GoogleFonts.inter(fontSize: 13)),
                trailing: Text(i['points'] ?? '',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10B981))),
              )),
          const Divider(),
          ..._data!.warnings.map((w) => ListTile(
                dense: true,
                leading: const Icon(Icons.remove_circle, color: Color(0xFFEF4444), size: 18),
                title: Text(w['action'] ?? '', style: GoogleFonts.inter(fontSize: 13)),
                trailing: Text(w['points'] ?? '',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFFEF4444))),
              )),
        ],
      ),
    );
  }

  Widget _historySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Score History', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_data!.history.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No history yet', style: GoogleFonts.inter(color: Colors.grey[500])),
            ),
          )
        else
          ..._data!.history.map((h) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: h.isPositive
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    child: Text(
                      h.isPositive ? '+${h.change}' : '${h.change}',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: h.isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    ),
                  ),
                  title: Text(h.description, style: GoogleFonts.inter(fontSize: 13)),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy').format(h.createdAt),
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                  ),
                  trailing: Text(
                    '${h.scoreBefore} → ${h.scoreAfter}',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              )),
      ],
    );
  }
}
