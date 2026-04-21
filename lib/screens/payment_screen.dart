import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/group_model.dart';
import '../services/api_client.dart';

class PaymentScreen extends StatefulWidget {
  final GroupModel group;
  const PaymentScreen({super.key, required this.group});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  final fmt = NumberFormat('#,##0', 'en_US');

  String _selectedMethod = 'MTN_MOMO';
  int _step = 1;
  bool _isLoading = false;
  String? _reference;
  Map<String, dynamic>? _payoutResult;

  double get _gross => widget.group.contributionAmt;
  double get _platformFee => _gross * 0.01;
  double get _insuranceFee => _gross * 0.005;
  double get _net => _gross - _platformFee - _insuranceFee;

  String _detectOperatorFromPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 3) return 'UNKNOWN';
    final prefix = int.parse(cleaned.substring(0, 3));
    if ((prefix >= 650 && prefix <= 659) || (prefix >= 670 && prefix <= 689)) {
      return 'MTN_MOMO';
    }
    if ((prefix >= 660 && prefix <= 669) || (prefix >= 690 && prefix <= 699)) {
      return 'ORANGE_MONEY';
    }
    return 'UNKNOWN';
  }

  void _onPhoneChanged(String phone) {
    final operator = _detectOperatorFromPhone(phone);
    if (operator != 'UNKNOWN' && operator != _selectedMethod) {
      setState(() => _selectedMethod = operator);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Detected ${operator == 'MTN_MOMO' ? 'MTN' : 'Orange'} number'),
          backgroundColor: const Color(0xFF1E3A8A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _initiate() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Enter your phone number', isError: true);
      return;
    }
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 9 || !cleaned.startsWith('6')) {
      _showSnack('Enter valid Cameroon number (6XXXXXXXX)', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.post('/payments/initiate', data: {
        'groupId': widget.group.id,
        'amount': _gross,
        'method': _selectedMethod,
        'phone': cleaned,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        _reference = response.data['data']['reference'];
        setState(() => _step = 4);
      } else {
        _showSnack(response.data['message'] ?? 'Payment failed', isError: true);
      }
    } catch (e) {
      _showSnack('Network error. Please try again.', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _confirm() async {
    if (_reference == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.post('/payments/confirm', data: {'reference': _reference});
      if (response.statusCode == 200) {
        _payoutResult = response.data['data']['payout'];
        setState(() => _step = 5);
      } else {
        _showSnack(response.data['message'] ?? 'Confirmation failed', isError: true);
      }
    } catch (e) {
      _showSnack('Confirmation failed', isError: true);
    }
    setState(() => _isLoading = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pay Contribution', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        leading: _step > 1 && _step < 5
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1: return _buildMethodStep();
      case 2: return _buildPhoneStep();
      case 3: return _buildConfirmStep();
      case 4: return _buildPinStep();
      case 5: return _buildSuccessStep();
      default: return _buildMethodStep();
    }
  }

  Widget _buildMethodStep() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _amountCard(),
          const SizedBox(height: 28),
          Text('Select Payment Method', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Your phone number will auto-detect the operator', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          _methodTile('MTN_MOMO', 'MTN Mobile Money', const Color(0xFFFFCC00), Icons.phone_android, 'Prefixes: 650-659, 670-689'),
          const SizedBox(height: 12),
          _methodTile('ORANGE_MONEY', 'Orange Money', const Color(0xFFFF6600), Icons.phone_iphone, 'Prefixes: 660-669, 690-699'),
          const SizedBox(height: 28),
          _feeBreakdown(),
          const SizedBox(height: 28),
          _primaryButton('Continue', () => setState(() => _step = 2)),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _amountCard(),
          const SizedBox(height: 28),
          Text('Enter Phone Number', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Enter your Mobile Money number', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 9,
            onChanged: _onPhoneChanged,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
            style: const TextStyle(fontSize: 22, letterSpacing: 2),
            decoration: InputDecoration(
              prefixText: '+237 ',
              hintText: '6XXXXXXXX',
              counterText: '',
              filled: true,
              fillColor: Colors.grey[50],
              helperText: _selectedMethod == 'MTN_MOMO' ? '✓ MTN number detected' : (_selectedMethod == 'ORANGE_MONEY' ? '✓ Orange number detected' : ''),
              helperStyle: TextStyle(
                color: _selectedMethod == 'MTN_MOMO' ? const Color(0xFFFFCC00) : const Color(0xFFFF6600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.note_outlined),
            ),
          ),
          const SizedBox(height: 32),
          _primaryButton('Continue', () => setState(() => _step = 3)),
        ],
      ),
    );
  }

  Widget _buildConfirmStep() {
    final phone = _phoneController.text.trim();
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    return SingleChildScrollView(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _amountCard(),
          const SizedBox(height: 24),
          Text('Confirm Payment', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _reviewRow('Group', widget.group.name),
                  _reviewRow('Method', _selectedMethod == 'MTN_MOMO' ? 'MTN Mobile Money' : 'Orange Money'),
                  _reviewRow('Phone', '+237 $cleaned'),
                  _reviewRow('Gross Amount', 'XAF ${fmt.format(_gross)}'),
                  const Divider(),
                  _reviewRow('Platform Fee (1%)', '- XAF ${fmt.format(_platformFee)}', isNegative: true),
                  _reviewRow('Insurance (0.5%)', '- XAF ${fmt.format(_insuranceFee)}', isNegative: true),
                  const Divider(),
                  _reviewRow('Net to Group Pot', 'XAF ${fmt.format(_net)}', isPositive: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _primaryButton(_isLoading ? 'Processing...' : 'Confirm & Send USSD', _isLoading ? null : _initiate, color: const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildPinStep() {
    final phone = _phoneController.text.trim();
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    return SingleChildScrollView(
      key: const ValueKey(4),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _selectedMethod == 'MTN_MOMO' ? const Color(0xFFFFCC00).withOpacity(0.15) : const Color(0xFFFF6600).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phone_in_talk_outlined, size: 72, color: _selectedMethod == 'MTN_MOMO' ? const Color(0xFFFFCC00) : const Color(0xFFFF6600)),
          ),
          const SizedBox(height: 28),
          Text('USSD Prompt Sent', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'A USSD prompt has been sent to\n+237 $cleaned\n\nDial *126# (MTN) or *144# (Orange) and enter your PIN to complete payment.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], height: 1.6),
          ),
          const SizedBox(height: 40),
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(child: Text('After entering your PIN, tap "I\'ve Completed Payment" below.', style: GoogleFonts.inter(fontSize: 13, color: Colors.blue[800]))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _primaryButton(_isLoading ? 'Verifying...' : "I've Completed Payment", _isLoading ? null : _confirm),
          const SizedBox(height: 12),
          TextButton(onPressed: () => setState(() => _step = 1), child: Text('Cancel Payment', style: GoogleFonts.inter(color: Colors.red[400], fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    final phone = _phoneController.text.trim();
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final hasPayout = _payoutResult != null;
    return SingleChildScrollView(
      key: const ValueKey(5),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 24),
          Text('Payment Successful! 🎉', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
          const SizedBox(height: 8),
          Text('XAF ${fmt.format(_gross)} contributed to\n${widget.group.name}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[600])),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _reviewRow('Amount', 'XAF ${fmt.format(_gross)}'),
                  _reviewRow('Method', _selectedMethod == 'MTN_MOMO' ? 'MTN MoMo' : 'Orange Money'),
                  _reviewRow('Phone', '+237 $cleaned'),
                  _reviewRow('Platform Fee', 'XAF ${fmt.format(_platformFee)}'),
                  _reviewRow('Insurance', 'XAF ${fmt.format(_insuranceFee)}'),
                  _reviewRow('Net to Pot', 'XAF ${fmt.format(_net)}', isPositive: true),
                  _reviewRow('Status', '✅ Success'),
                ],
              ),
            ),
          ),
          if (hasPayout) ...[
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFFFFF7ED),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Text('🎊', style: TextStyle(fontSize: 24)), const SizedBox(width: 8), Expanded(child: Text('Cycle Complete! Winner: ${_payoutResult!['winner']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)))]),
                    const SizedBox(height: 12),
                    _reviewRow('Total Pot', 'XAF ${fmt.format(_payoutResult!['totalPot'])}'),
                    _reviewRow('Sent Now', 'XAF ${fmt.format(_payoutResult!['nowAmount'])}', isPositive: true),
                    _reviewRow('Held in Escrow', 'XAF ${fmt.format(_payoutResult!['heldAmount'])}', isWarning: true),
                    _reviewRow('Next Winner', _payoutResult!['nextWinner'] ?? 'TBD'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          _primaryButton('Done', () => Navigator.pop(context, true)),
        ],
      ),
    );
  }

  Widget _amountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('Amount Due', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text('XAF ${fmt.format(_gross)}', style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(widget.group.name, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _methodTile(String value, String label, Color color, IconData icon, String subtitle) {
    final selected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? const Color(0xFF1E3A8A) : Colors.grey[200]!, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
          color: selected ? const Color(0xFF1E3A8A).withOpacity(0.04) : Colors.white,
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)), Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]))])),
            Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: selected ? const Color(0xFF1E3A8A) : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _feeBreakdown() {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fee Breakdown', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            _feeRow('Group contribution', 'XAF ${fmt.format(_gross)}'),
            _feeRow('Platform fee (1%)', '- XAF ${fmt.format(_platformFee)}', Colors.red),
            _feeRow('Insurance (0.5%)', '- XAF ${fmt.format(_insuranceFee)}', Colors.orange),
            const Divider(height: 16),
            _feeRow('Net to pot', 'XAF ${fmt.format(_net)}', const Color(0xFF10B981), true),
          ],
        ),
      ),
    );
  }

  Widget _feeRow(String label, String value, [Color? valueColor, bool bold = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: valueColor)),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value, {bool isNegative = false, bool isPositive = false, bool isWarning = false}) {
    Color? textColor;
    if (isPositive) textColor = const Color(0xFF10B981);
    if (isNegative) textColor = Colors.red;
    if (isWarning) textColor = Colors.orange;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap, {Color color = const Color(0xFF1E3A8A)}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
