import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/group_model.dart';
import '../providers/auth_provider.dart';
import '../services/group_service.dart';
import 'payment_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GroupDetailModel? _detail;
  bool _isLoading = true;
  final fmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final result = await GroupService.getGroupById(widget.group.id);
    if (result['success'] && mounted) {
      setState(() {
        _detail = result['group'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _activateGroup() async {
    final result = await GroupService.activateGroup(widget.group.id);
    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group activated!'), backgroundColor: Color(0xFF10B981)),
      );
      _loadDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().user?.id;
    final isAdmin = _detail?.members
            .any((m) => m.userId == myId && m.role == 'ADMIN') ??
        false;
    final g = _detail?.group ?? widget.group;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(g.name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                            _statusChip(g.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('XAF ${fmt.format(g.contributionAmt)} • ${g.frequency}',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.vpn_key_outlined, size: 14, color: Colors.white60),
                            const SizedBox(width: 4),
                            Text('Invite: ${g.inviteCode}',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: g.inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invite code copied!')),
                                );
                              },
                              child: const Icon(Icons.copy, size: 14, color: Colors.white60),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Members'),
                Tab(text: 'Transactions'),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverview(g, isAdmin, myId),
                  _buildMembers(myId),
                  _buildTransactions(),
                ],
              ),
      ),
      bottomNavigationBar: g.status == 'ACTIVE'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final paid = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(group: g),
                      ),
                    );
                    if (paid == true) _loadDetails();
                  },
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                    'Pay XAF ${fmt.format(g.contributionAmt)}',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            )
          : (isAdmin && g.status == 'PENDING'
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _activateGroup,
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text('Activate Group',
                          style:
                              GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                )
              : null),
    );
  }

  Widget _buildOverview(GroupModel g, bool isAdmin, String? myId) {
    final nextPayout = _detail?.group != null
        ? _detail!.members
            .where((m) => true)
            .toList()
        : <GroupMemberModel>[];

    return RefreshIndicator(
      onRefresh: _loadDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _statCard('Escrow Balance',
                      'XAF ${fmt.format(_detail?.escrowBalance ?? 0)}',
                      Icons.account_balance_outlined, const Color(0xFF1E3A8A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard('My Contributions',
                      'XAF ${fmt.format(_detail?.myContributions ?? 0)}',
                      Icons.trending_up, const Color(0xFF10B981)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard('Members',
                      '${_detail?.members.length ?? 0} / ${g.maxMembers}',
                      Icons.people_outlined, const Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard('Start Date',
                      DateFormat('MMM d, yyyy').format(g.startDate),
                      Icons.calendar_today_outlined, const Color(0xFF8B5CF6)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Group info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Group Info',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _infoRow('Frequency', g.frequency),
                    _infoRow('Contribution', 'XAF ${fmt.format(g.contributionAmt)}'),
                    _infoRow('Total Payout',
                        'XAF ${fmt.format(g.contributionAmt * g.maxMembers)}'),
                    _infoRow('Max Members', '${g.maxMembers}'),
                    if (g.description != null && g.description!.isNotEmpty)
                      _infoRow('Description', g.description!),
                  ],
                ),
              ),
            ),

            if (isAdmin && g.status == 'PENDING') ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Share the invite code with members, then activate the group to start contributions.',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.amber[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMembers(String? myId) {
    final members = _detail?.members ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final m = members[index];
        final isMe = m.userId == myId;
        final payoutDate = _detail?.group.startDate != null
            ? _detail!.group.startDate.add(Duration(
                days: _frequencyDays(_detail!.group.frequency) * ((m.payoutOrder ?? 1) - 1)))
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isMe
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : const Color(0xFF1E3A8A).withOpacity(0.1),
              child: Text(
                m.fullName.substring(0, 1).toUpperCase(),
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: isMe ? const Color(0xFF10B981) : const Color(0xFF1E3A8A)),
              ),
            ),
            title: Row(
              children: [
                Text(m.fullName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('You',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
                if (m.role == 'ADMIN') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Admin',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trust Score: ${m.trustScore}%',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
                if (payoutDate != null)
                  Text('Payout: ${DateFormat('MMM d, yyyy').format(payoutDate)}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8B5CF6))),
              ],
            ),
            trailing: m.payoutOrder != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('#${m.payoutOrder}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.grey[400])),
                      Text('order',
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400])),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildTransactions() {
    final transactions = _detail?.group != null ? [] : [];
    // We'll pull transactions from the group detail
    final txList = _detail != null
        ? (_detail!.group as dynamic) // access via raw json stored
        : null;

    // Since our GroupDetailModel doesn't store transactions separately,
    // we show a message directing to History tab
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Group Transactions',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(
              'All contributions and payouts for this group appear in your History tab.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 15, color: color)),
            Text(label,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
          Text(value,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'ACTIVE'
        ? const Color(0xFF10B981)
        : status == 'PENDING'
            ? Colors.amber
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(status,
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  int _frequencyDays(String freq) {
    switch (freq) {
      case 'DAILY': return 1;
      case 'WEEKLY': return 7;
      case 'BIWEEKLY': return 14;
      default: return 30;
    }
  }
}
