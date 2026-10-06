import 'package:flutter/material.dart';
import '../controllers/relief_tracking_controller.dart';
import '../widgets/camp_capacity_card.dart';
import '../widgets/supply_item_tile.dart';
import '../widgets/add_stock_dialog.dart';

class CampDashboardScreen extends StatefulWidget {
  const CampDashboardScreen({super.key});

  @override
  State<CampDashboardScreen> createState() => _CampDashboardScreenState();
}

class _CampDashboardScreenState extends State<CampDashboardScreen> {
  late final ReliefTrackingController _controller;
  int _currentIndex = 0; // 0: Dashboard, 1: Supplies, 2: Alerts, 3: Profile, 4: Team

  @override
  void initState() {
    super.initState();
    _controller = ReliefTrackingController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddStockDialog() {
    showDialog(
      context: context,
      builder: (context) => AddStockDialog(
        onItemAdded: (item) {
          _controller.addInventoryItem(item);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} added to inventory!'),
              backgroundColor: const Color(0xFF30D158),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101D), // Dark Navy Background matching Figma
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboardTab(),
            _buildSuppliesTab(),
            _buildAlertsTab(),
            _buildProfileTab(),
            _buildTeamTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1424),
          border: Border(top: BorderSide(color: Color(0xFF1E283D), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF0D1424),
          selectedItemColor: const Color(0xFFFF5252), // Active top accent highlight
          unselectedItemColor: const Color(0xFF5E6D82),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.widgets_outlined),
              label: 'Supplies',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline_rounded),
              label: 'Team',
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 0: DASHBOARD (Image 1 Iframe) ---
  Widget _buildDashboardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CampCapacityCard(controller: _controller),
      ],
    );
  }

  // --- TAB 1: SUPPLIES (Image 2 frame2) ---
  Widget _buildSuppliesTab() {
    final items = _controller.filteredInventory;
    final shipment = _controller.incomingShipment;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header: Title & Add Item Link
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RATION & MEDICAL LOG',
              style: TextStyle(
                color: Color(0xFF7E8B9B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: _showAddStockDialog,
              child: const Text(
                '+ Add Item',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Swipe Hint Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              '← SWIPE: MARK EMPTY  |  SWIPE: LOW →',
              style: TextStyle(
                color: Color(0xFF8E9BAE),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSupplyFilterChip('All', 'All (18)', _controller.selectedSupplyFilter == 'All'),
              _buildSupplyFilterChip('Depleted', 'Depleted (2)', _controller.selectedSupplyFilter == 'Depleted', outlineColor: const Color(0xFFFF3B30)),
              _buildSupplyFilterChip('Low', 'Low (3)', _controller.selectedSupplyFilter == 'Low', outlineColor: const Color(0xFFFF9F0A)),
              _buildSupplyFilterChip('Adequate', 'Adequate (13)', _controller.selectedSupplyFilter == 'Adequate', outlineColor: const Color(0xFF1E283D)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stock Items List
        ...items.map((item) {
          return SupplyItemTile(
            item: item,
            onQuantityChanged: (delta) => _controller.updateStockQuantity(item.id, delta),
          );
        }),

        const SizedBox(height: 20),

        // Incoming Shipment Tracking Tile (Matching Image 2 frame2)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E283D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF063327),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF30D158), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shipment['title'],
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            shipment['subtitle'],
                            style: const TextStyle(color: Color(0xFF7E8B9B), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF063327),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      shipment['eta'],
                      style: const TextStyle(color: Color(0xFF30D158), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: shipment['progress'],
                  minHeight: 6,
                  backgroundColor: const Color(0xFF1E283D),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF30D158)),
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons: Call Driver & Confirm Restock
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(color: Color(0xFF2C3954)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling Driver: ${shipment['driverPhone']}')),
                        );
                      },
                      icon: const Icon(Icons.phone_outlined, color: Colors.white, size: 16),
                      label: const Text('Call Driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: shipment['isRestocked'] ? Colors.grey : Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: shipment['isRestocked'] ? null : () => _controller.confirmRestock(),
                      child: Text(
                        shipment['isRestocked'] ? 'Restocked' : 'Confirm Restock',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupplyFilterChip(String value, String label, bool isSelected, {Color? outlineColor}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _controller.setSupplyFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFF131A2A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white : (outlineColor ?? const Color(0xFF1E283D)),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 2: ALERTS (Image 3 alert d.) ---
  Widget _buildAlertsTab() {
    final alerts = _controller.filteredAlerts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Alerts',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),

        // Alert Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAlertFilterChip('All', 'All 12', _controller.selectedAlertFilter == 'All', activeColor: const Color(0xFFFF3B30)),
              _buildAlertFilterChip('Critical', 'Critical 3', _controller.selectedAlertFilter == 'Critical'),
              _buildAlertFilterChip('Low Stock', 'Low Stock 5', _controller.selectedAlertFilter == 'Low Stock'),
              _buildAlertFilterChip('Logs', 'Logs 4', _controller.selectedAlertFilter == 'Logs'),
            ],
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          'TODAY',
          style: TextStyle(color: Color(0xFF7E8B9B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),

        ...alerts.map((alert) {
          final isCritical = alert['type'] == 'critical';
          final isLow = alert['type'] == 'low';
          final isLogs = alert['type'] == 'logs';

          Color cardBorderColor = isCritical
              ? const Color(0xFFFF3B30)
              : isLow
                  ? const Color(0xFFFF9F0A)
                  : const Color(0xFF30D158);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF131A2A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorderColor.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardBorderColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCritical
                            ? Icons.warning_amber_rounded
                            : isLow
                                ? Icons.show_chart
                                : Icons.check_circle_outline,
                        color: cardBorderColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  alert['title'],
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                alert['time'],
                                style: const TextStyle(color: Color(0xFF63738A), fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert['subtitle'],
                            style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLogs ? const Color(0xFF30D158) : const Color(0xFFFF3B30),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Triggered: ${alert['actionText']}')),
                          );
                        },
                        child: Text(
                          alert['actionText'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E283D),
                          foregroundColor: const Color(0xFF8E9BAE),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _controller.dismissAlert(alert['id']),
                        child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAlertFilterChip(String value, String label, bool isSelected, {Color? activeColor}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _controller.setAlertFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? (activeColor ?? const Color(0xFF1E283D)) : const Color(0xFF131A2A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E283D)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF8E9BAE),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 3: PROFILE (Image 4 profile d.) ---
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Profile Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF131A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E283D)),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2C46),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'RS',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _controller.leaderName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Relief Team Lead - ${_controller.campName}',
                style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF063327),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF30D158), size: 6),
                    SizedBox(width: 6),
                    Text(
                      'ON DUTY',
                      style: TextStyle(color: Color(0xFF30D158), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Stats Row (14 Shelters, 3.2K People Aided, 98% Sync Uptime)
        Row(
          children: [
            _buildProfileStatTile('14', 'SHELTERS'),
            const SizedBox(width: 8),
            _buildProfileStatTile('3.2K', 'PEOPLE AIDED'),
            const SizedBox(width: 8),
            _buildProfileStatTile('98%', 'SYNC UPTIME'),
          ],
        ),
        const SizedBox(height: 18),

        // Account Settings List Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E283D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACCOUNT',
                style: TextStyle(color: Color(0xFF7E8B9B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),
              _buildAccountRow(Icons.person_outline, 'Personal Information', 'Name, ID, contact details'),
              const Divider(color: Color(0xFF1E283D), height: 16),
              _buildAccountRow(Icons.night_shelter_outlined, 'Assigned Shelters', 'Camp Nēraya, Camp Dawn Ridge'),
              const Divider(color: Color(0xFF1E283D), height: 16),
              _buildAccountRow(
                Icons.key_outlined,
                'Role & Permissions',
                'Relief Team Lead',
                badgeText: 'VERIFIED',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Log out Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logging out...')),
              );
            },
            child: const Text(
              'Log out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStatTile(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E283D)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF63738A), fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow(IconData icon, String title, String subtitle, {String? badgeText}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2C46),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF448AFF), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF7E8B9B), fontSize: 10),
              ),
            ],
          ),
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF063327),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(color: Color(0xFF30D158), fontSize: 9, fontWeight: FontWeight.bold),
            ),
          )
        else
          const Icon(Icons.chevron_right, color: Color(0xFF5E6D82), size: 18),
      ],
    );
  }

  // --- TAB 4: TEAM / COMMUNITY CHAT (Image 3 frame5) ---
  Widget _buildTeamTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          color: const Color(0xFF131A2A),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF1F2C46),
                child: Icon(Icons.people, color: Colors.white, size: 16),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Community Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('● 12 online • Kolonnawa Zone 04', style: TextStyle(color: Color(0xFF30D158), fontSize: 10)),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildChatMessage('Nadeesha F.', 'Water levels rising near Gate B. We need sandbags urgently.', '10:42'),
              const SizedBox(height: 10),
              _buildChatMessage('Priya M.', 'Convoy B is 18 mins out with water + formula. Hang tight.', '10:44'),
              const SizedBox(height: 10),
              _buildChatMessage('Dr. Rohan Silva', 'Copy. Redirecting volunteers to Gate B now. Keep me posted on the ETA.', '10:45', isSelf: true),
              const SizedBox(height: 10),
              _buildChatMessage('Nadeesha F.', 'Can DMC expedite this one?', '10:47'),
              const SizedBox(height: 10),
              _buildChatMessage('Dr. Rohan Silva', 'Escalating to DMC now. Dispatch #MED-042 is in.', '10:48', isSelf: true),
            ],
          ),
        ),

        // Chat Input Bar
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF131A2A),
          child: Row(
            children: [
              const Icon(Icons.attach_file, color: Color(0xFF7E8B9B)),
              const SizedBox(width: 10),
              const Expanded(
                child: TextField(
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Message the team...',
                    hintStyle: TextStyle(color: Color(0xFF5E6D82), fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFFF5252),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessage(String sender, String text, String time, {bool isSelf = false}) {
    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelf ? const Color(0xFF1E2C48) : const Color(0xFF131A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E283D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sender, style: TextStyle(color: isSelf ? const Color(0xFF448AFF) : const Color(0xFF30D158), fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(time, style: const TextStyle(color: Color(0xFF5E6D82), fontSize: 9)),
            ),
          ],
        ),
      ),
    );
  }
}