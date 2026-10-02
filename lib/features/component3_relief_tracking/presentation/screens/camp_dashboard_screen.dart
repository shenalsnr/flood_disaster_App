import 'package:flutter/material.dart';
import '../controllers/relief_tracking_controller.dart';
import '../../data/models/relief_item_model.dart';
import '../../data/models/evacuee_model.dart';
import '../widgets/camp_capacity_card.dart';
import '../widgets/supply_item_tile.dart';
import '../widgets/evacuee_tile.dart';
import '../widgets/relief_request_card.dart';
import '../widgets/register_evacuee_dialog.dart';
import '../widgets/new_request_dialog.dart';
import '../widgets/add_stock_dialog.dart';

class CampDashboardScreen extends StatefulWidget {
  const CampDashboardScreen({super.key});

  @override
  State<CampDashboardScreen> createState() => _CampDashboardScreenState();
}

class _CampDashboardScreenState extends State<CampDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final ReliefTrackingController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = ReliefTrackingController();
    _tabController = TabController(length: 4, vsync: this);
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showRegisterEvacueeDialog() {
    showDialog(
      context: context,
      builder: (context) => RegisterEvacueeDialog(
        onEvacueeRegistered: (evacuee) {
          _controller.registerEvacuee(evacuee);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Evacuee ${evacuee.fullName} registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showNewRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => NewRequestDialog(
        onRequestSubmitted: (request) {
          _controller.addReliefRequest(request);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Requisition for ${request.itemTitle} submitted to Central Dispatch!'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        },
      ),
    );
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
              backgroundColor: Colors.blueAccent,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 2,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Camp Relief & Logistics',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Component 3: Relief Tracking',
              style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_outlined, color: Colors.greenAccent),
            tooltip: 'Live WebSocket Connected',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing latest camp metrics with server...')),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildSuppliesTab(),
          _buildEvacueesTab(),
          _buildRequisitionsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabController.index,
          onTap: (index) {
            _tabController.animateTo(index);
          },
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white54,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Supplies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Evacuees',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Requisitions',
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton.extended(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          onPressed: _showAddStockDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Supply Item', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      case 2:
        return FloatingActionButton.extended(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black,
          onPressed: _showRegisterEvacueeDialog,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Check-in Evacuee', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      case 3:
        return FloatingActionButton.extended(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.black,
          onPressed: _showNewRequestDialog,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Request Stock', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      default:
        return null;
    }
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab() {
    final criticalItems = _controller.inventoryItems.where((i) => i.status == StockStatus.critical).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CampCapacityCard(controller: _controller),
        const SizedBox(height: 20),

        // Quick Action Shortcuts
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.white10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _tabController.animateTo(2);
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Check-in Evacuee'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.white10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _tabController.animateTo(3);
                },
                icon: const Icon(Icons.request_quote_outlined, size: 18),
                label: const Text('Request Stock'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Critical Depletion Alerts
        const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'CRITICAL STOCK DEPLETION ALERTS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (criticalItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                SizedBox(width: 12),
                Text(
                  'All supply items are at safe threshold levels.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...criticalItems.map((item) {
            return SupplyItemTile(
              item: item,
              onQuantityChanged: (delta) => _controller.updateStockQuantity(item.id, delta),
            );
          }),

        const SizedBox(height: 24),

        // Critical Triage Evacuees Summary
        const Row(
          children: [
            Icon(Icons.personal_injury_outlined, color: Colors.redAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'HIGH PRIORITY TRIAGE PATIENTS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ..._controller.evacuees.where((e) => e.triage == TriagePriority.red).map((evacuee) {
          return EvacueeTile(
            evacuee: evacuee,
            onTriageChanged: (newTriage) => _controller.updateEvacueeTriage(evacuee.id, newTriage),
          );
        }),
      ],
    );
  }

  // --- TAB 2: INVENTORY & SUPPLIES ---
  Widget _buildSuppliesTab() {
    final items = _controller.filteredInventory;

    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E1E1E),
          child: Column(
            children: [
              // Search Field
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search inventory items...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => _controller.setInventorySearchQuery(val),
              ),
              const SizedBox(height: 10),

              // Category Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryFilterChip(null, 'ALL STOCK'),
                    ...SupplyCategory.values.map((cat) {
                      return _buildCategoryFilterChip(cat, cat.name.toUpperCase());
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Inventory Item List
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 64),
                      SizedBox(height: 12),
                      Text('No matching inventory items', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SupplyItemTile(
                      item: item,
                      onQuantityChanged: (delta) => _controller.updateStockQuantity(item.id, delta),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChip(SupplyCategory? category, String label) {
    final bool isSelected = _controller.selectedInventoryCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.blueAccent,
        backgroundColor: const Color(0xFF2C2C2C),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        onSelected: (selected) {
          _controller.setInventoryCategory(selected ? category : null);
        },
      ),
    );
  }

  // --- TAB 3: EVACUEES & TRIAGE ---
  Widget _buildEvacueesTab() {
    final list = _controller.filteredEvacuees;

    return Column(
      children: [
        // Search & Triage Filter Header
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E1E1E),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search evacuee name or zone...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => _controller.setEvacueeSearchQuery(val),
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTriageFilterChip(null, 'ALL EVACUEES'),
                    _buildTriageFilterChip(TriagePriority.red, 'RED (URGENT)'),
                    _buildTriageFilterChip(TriagePriority.yellow, 'YELLOW (CARE)'),
                    _buildTriageFilterChip(TriagePriority.green, 'GREEN (STABLE)'),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_outlined, color: Colors.white24, size: 64),
                      SizedBox(height: 12),
                      Text('No matching evacuees found', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final evacuee = list[index];
                    return EvacueeTile(
                      evacuee: evacuee,
                      onTriageChanged: (newTriage) => _controller.updateEvacueeTriage(evacuee.id, newTriage),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTriageFilterChip(TriagePriority? priority, String label) {
    final bool isSelected = _controller.selectedTriageFilter == priority;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: priority == TriagePriority.red
            ? const Color(0xFFFF5252)
            : priority == TriagePriority.yellow
                ? const Color(0xFFFFAB40)
                : priority == TriagePriority.green
                    ? const Color(0xFF69F0AE)
                    : Colors.blueAccent,
        backgroundColor: const Color(0xFF2C2C2C),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white60,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        onSelected: (selected) {
          _controller.setTriageFilter(selected ? priority : null);
        },
      ),
    );
  }

  // --- TAB 4: REQUISITIONS & AID SHIPMENTS ---
  Widget _buildRequisitionsTab() {
    final requests = _controller.reliefRequests;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blueAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Requisitions submitted here sync live with Component 4 Control Center for dispatch approval.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...requests.map((req) => ReliefRequestCard(request: req)),
      ],
    );
  }
}