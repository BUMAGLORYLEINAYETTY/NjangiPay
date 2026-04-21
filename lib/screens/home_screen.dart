import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/group_model.dart';
import '../models/transaction_model.dart';
import 'login_screen.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';
import 'group_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardTab(),
    GroupsTab(),
    TransactionsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: 'Groups'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ─── DASHBOARD ────────────────────────────────────────────────────────────────

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchSummary();
      context.read<GroupProvider>().fetchGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final summaryProvider = context.watch<TransactionProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final summary = summaryProvider.summary;
    final fmt = NumberFormat('#,##0', 'en_US');

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await context.read<TransactionProvider>().fetchSummary();
          await context.read<GroupProvider>().fetchGroups();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good morning,', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
                      Text('${user?.fullName ?? 'User'} 👋',
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                    ],
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF1E3A8A),
                    child: Text(
                      user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: summaryProvider.isLoading
                    ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator(color: Colors.white)))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Contributed', style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('XAF ${fmt.format(summary?.totalContributed ?? 0)}',
                              style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _statItem('Active Groups', '${summary?.activeGroups ?? 0}'),
                              _statItem('Total Received', 'XAF ${fmt.format(summary?.totalReceived ?? 0)}'),
                              _statItem('Trust Score', '${user?.trustScore ?? 100}%'),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 28),

              // Quick actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _actionButton(Icons.add_circle_outline, 'New Group', const Color(0xFF1E3A8A), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()))
                        .then((_) {
                      context.read<GroupProvider>().fetchGroups();
                      context.read<TransactionProvider>().fetchSummary();
                    });
                  }),
                  _actionButton(Icons.group_add_outlined, 'Join Group', const Color(0xFF10B981), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinGroupScreen()))
                        .then((_) => context.read<GroupProvider>().fetchGroups());
                  }),
                  _actionButton(Icons.receipt_long_outlined, 'History', const Color(0xFFF59E0B), () {}),
                  _actionButton(Icons.person_outline, 'Profile', const Color(0xFF8B5CF6), () {}),
                ],
              ),
              const SizedBox(height: 28),

              // Groups
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Groups', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text('See All')),
                ],
              ),
              const SizedBox(height: 8),
              if (groupProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (groupProvider.groups.isEmpty)
                _emptyState(Icons.group_outlined, 'No groups yet', 'Create or join a Njangi group')
              else
                ...groupProvider.groups.take(3).map((g) => _groupCard(context, g)),

              const SizedBox(height: 28),

              // Recent transactions
              Text('Recent Transactions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (summary == null || summary.recentTransactions.isEmpty)
                _emptyState(Icons.receipt_outlined, 'No transactions yet', 'Contributions will appear here')
              else
                ...summary.recentTransactions.map((t) => _transactionCard(t, fmt)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _groupCard(BuildContext context, GroupModel g) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: g)),
        ).then((_) {
          context.read<GroupProvider>().fetchGroups();
          context.read<TransactionProvider>().fetchSummary();
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                child: Text(g.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('XAF ${NumberFormat('#,##0').format(g.contributionAmt)} • ${g.frequency}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: g.status == 'ACTIVE'
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(g.status,
                    style: GoogleFonts.inter(
                        color: g.status == 'ACTIVE' ? const Color(0xFF10B981) : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionCard(TransactionModel t, NumberFormat fmt) {
    final isDebit = t.isDebit;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDebit
              ? const Color(0xFFEF4444).withOpacity(0.1)
              : const Color(0xFF10B981).withOpacity(0.1),
          child: Icon(isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
        ),
        title: Text(t.group?['name'] ?? t.type,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(DateFormat('MMM d, h:mm a').format(t.createdAt),
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
        trailing: Text('${isDebit ? '-' : '+'}XAF ${fmt.format(t.amount)}',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[600])),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

// ─── GROUPS TAB ───────────────────────────────────────────────────────────────

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Groups',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()))
                        .then((_) => context.read<GroupProvider>().fetchGroups()),
                    icon: const Icon(Icons.add),
                    label: const Text('Create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const JoinGroupScreen()))
                        .then((_) => context.read<GroupProvider>().fetchGroups()),
                    icon: const Icon(Icons.vpn_key_outlined),
                    label: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: groupProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : groupProvider.groups.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group_add_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No groups yet',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[600])),
                              Text('Create your first Njangi group',
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => context.read<GroupProvider>().fetchGroups(),
                          child: ListView.builder(
                            itemCount: groupProvider.groups.length,
                            itemBuilder: (context, index) {
                              final g = groupProvider.groups[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: g)),
                                  ).then((_) => context.read<GroupProvider>().fetchGroups()),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                                          child: Text(g.name.substring(0, 1).toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF1E3A8A),
                                                  fontSize: 18)),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(g.name,
                                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                                              const SizedBox(height: 2),
                                              Text('XAF ${NumberFormat('#,##0').format(g.contributionAmt)} • ${g.frequency}',
                                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                                              Text('${g.memberCount ?? 0}/${g.maxMembers} members • ${g.inviteCode}',
                                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400])),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Chip(
                                              label: Text(g.status,
                                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600)),
                                              backgroundColor: g.status == 'ACTIVE'
                                                  ? const Color(0xFF10B981).withOpacity(0.15)
                                                  : Colors.orange.withOpacity(0.15),
                                              labelStyle: TextStyle(
                                                  color: g.status == 'ACTIVE'
                                                      ? const Color(0xFF10B981)
                                                      : Colors.orange),
                                              padding: EdgeInsets.zero,
                                            ),
                                            if (g.myRole == 'ADMIN')
                                              Text('Admin',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      color: const Color(0xFF1E3A8A),
                                                      fontWeight: FontWeight.w600)),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TRANSACTIONS TAB ─────────────────────────────────────────────────────────

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final fmt = NumberFormat('#,##0', 'en_US');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction History',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No transactions yet', style: GoogleFonts.poppins(color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => context.read<TransactionProvider>().fetchTransactions(),
                          child: ListView.builder(
                            itemCount: provider.transactions.length,
                            itemBuilder: (context, index) {
                              final t = provider.transactions[index];
                              final isDebit = t.isDebit;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isDebit
                                        ? const Color(0xFFEF4444).withOpacity(0.1)
                                        : const Color(0xFF10B981).withOpacity(0.1),
                                    child: Icon(isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                                        color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                                  ),
                                  title: Text(t.group?['name'] ?? t.type,
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Text(DateFormat('MMM d, yyyy • h:mm a').format(t.createdAt),
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
                                  trailing: Text('${isDebit ? '-' : '+'}XAF ${fmt.format(t.amount)}',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROFILE TAB ──────────────────────────────────────────────────────────────

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1E3A8A),
              child: Text(user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                  style: GoogleFonts.poppins(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(user?.fullName ?? '',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.email ?? '', style: GoogleFonts.inter(color: Colors.grey[600])),
            Text(user?.phone ?? '', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Trust Score: ${user?.trustScore ?? 100}%',
                  style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
            _option(Icons.notifications_outlined, 'Notifications', () {}),
            _option(Icons.security_outlined, 'Security', () {}),
            _option(Icons.help_outline, 'Help & Support', () {}),
            _option(Icons.info_outline, 'About NjangiPay', () {}),
            const SizedBox(height: 8),
            _option(Icons.logout, 'Logout', () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _option(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFEF4444) : const Color(0xFF1E3A8A);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: isDestructive ? color : null)),
        trailing: isDestructive ? null : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
