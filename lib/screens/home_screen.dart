import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

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
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
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

// ─── DASHBOARD TAB ────────────────────────────────────────────────────────────

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildHeader(),
            const SizedBox(height: 24),
            _buildBalanceCard(),
            const SizedBox(height: 28),
            _buildQuickActions(context),
            const SizedBox(height: 28),
            _buildSectionHeader('Active Njangi Groups'),
            const SizedBox(height: 12),
            _buildGroupList(),
            const SizedBox(height: 28),
            _buildSectionHeader('Recent Transactions'),
            const SizedBox(height: 12),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good morning,', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
            Text(
              'John Doe 👋',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
            ),
          ],
        ),
        Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1E3A8A),
              child: const Icon(Icons.person, size: 28, color: Colors.white),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Savings', style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'XAF 250,000',
            style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF34D399), size: 16),
              const SizedBox(width: 4),
              Text('+12.5% this month', style: GoogleFonts.inter(color: const Color(0xFF34D399), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Active Groups', '3'),
              _buildStatItem('Next Payout', '5 days'),
              _buildStatItem('Trust Score', '98%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.add_circle_outline, 'label': 'New Group', 'color': const Color(0xFF1E3A8A)},
      {'icon': Icons.send_outlined, 'label': 'Pay', 'color': const Color(0xFF10B981)},
      {'icon': Icons.download_outlined, 'label': 'Withdraw', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.qr_code_outlined, 'label': 'Scan QR', 'color': const Color(0xFF8B5CF6)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (a['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(a['label'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () {}, child: const Text('See All')),
      ],
    );
  }

  Widget _buildGroupList() {
    final groups = [
      {'name': 'Family Savings', 'amount': 'XAF 15,000/month', 'members': 8, 'color': const Color(0xFF1E3A8A)},
      {'name': 'Office Colleagues', 'amount': 'XAF 10,000/week', 'members': 6, 'color': const Color(0xFF10B981)},
      {'name': 'Church Group', 'amount': 'XAF 5,000/week', 'members': 12, 'color': const Color(0xFFF59E0B)},
    ];

    return Column(
      children: groups.map((g) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: (g['color'] as Color).withOpacity(0.15),
              child: Icon(Icons.group, color: g['color'] as Color),
            ),
            title: Text(g['name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(g['amount'] as String, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Active', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 4),
                Text('${g['members']} members', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionList() {
    final transactions = [
      {'name': 'Family Savings', 'date': 'Today, 9:00 AM', 'amount': '-XAF 15,000', 'isDebit': true},
      {'name': 'Payout Received', 'date': 'Yesterday, 2:30 PM', 'amount': '+XAF 120,000', 'isDebit': false},
      {'name': 'Office Colleagues', 'date': 'Apr 13, 10:00 AM', 'amount': '-XAF 10,000', 'isDebit': true},
    ];

    return Column(
      children: transactions.map((t) {
        final isDebit = t['isDebit'] as bool;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isDebit
                  ? const Color(0xFFEF4444).withOpacity(0.1)
                  : const Color(0xFF10B981).withOpacity(0.1),
              child: Icon(
                isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ),
            title: Text(t['name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(t['date'] as String, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
            trailing: Text(
              t['amount'] as String,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── GROUPS TAB ───────────────────────────────────────────────────────────────

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Groups', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Create New Group'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_add_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Groups screen coming soon', style: GoogleFonts.inter(color: Colors.grey[500])),
                  ],
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

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction History', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Full history coming soon', style: GoogleFonts.inter(color: Colors.grey[500])),
                  ],
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

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1E3A8A),
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('John Doe', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('john.doe@email.com', style: GoogleFonts.inter(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Trust Score: 98%', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
            _buildProfileOption(Icons.notifications_outlined, 'Notifications', () {}),
            _buildProfileOption(Icons.security_outlined, 'Security', () {}),
            _buildProfileOption(Icons.help_outline, 'Help & Support', () {}),
            _buildProfileOption(Icons.info_outline, 'About NjangiPay', () {}),
            const SizedBox(height: 8),
            _buildProfileOption(Icons.logout, 'Logout', () => _logout(context), isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFEF4444) : const Color(0xFF1E3A8A);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: isDestructive ? color : null)),
        trailing: isDestructive ? null : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
