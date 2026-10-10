import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/relief_item_model.dart';
import '../controllers/relief_tracking_controller.dart';
import '../widgets/camp_capacity_card.dart';
import '../widgets/supply_item_tile.dart';
import '../widgets/add_stock_dialog.dart';
import '../widgets/leaders_chat_panel.dart';
import '../widgets/request_supply_dialog.dart';
import '../widgets/supply_requests_list.dart';
import 'supply_admin_dashboard_screen.dart';
import 'relief_truck_tracking_screen.dart';
import 'equipment_tracking_screen.dart';
import 'personal_information_screen.dart';
import '../../../component4_control_center/data/services/session_service.dart';
import '../../../component4_control_center/presentation/screens/responder_login_screen.dart';
import '../widgets/leader_avatar.dart';
import '../../../component4_control_center/presentation/controllers/responder_controller.dart';
import '../../../component1_evacuation/models/warning_alert.dart';

class CampDashboardScreen extends StatefulWidget {
  const CampDashboardScreen({super.key});

  @override
  State<CampDashboardScreen> createState() => _CampDashboardScreenState();
}

class _CampDashboardScreenState extends State<CampDashboardScreen> {
  late final ReliefTrackingController _controller;
  int _currentIndex =
      0; // 0: Dashboard, 1: Supplies, 2: Alerts, 3: Profile, 4: Team

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

  /// Opens the Request Supply form. When [item] is given the form is
  /// pre-filled for it. After sending, a confirmation popup is shown.
  Future<void> _showRequestSupplyDialog({ReliefItemModel? item}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          RequestSupplyDialog(controller: _controller, prefillItem: item),
    );
    if (!mounted || result == null) return;
    await _showRequestSentPopup(result);
  }

  Future<void> _showRequestSentPopup(Map<String, dynamic> r) {
    final queued = r['status'] == 'queued';
    final qty = r['quantity'] as double;
    final qtyText = qty == qty.roundToDouble()
        ? qty.round().toString()
        : qty.toString();
    final color = queued ? const Color(0xFFFF9F0A) : const Color(0xFF30D158);

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E283D)),
        ),
        title: Row(
          children: [
            Icon(queued ? Icons.cloud_off : Icons.check_circle, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                queued ? 'Request saved' : 'Request sent',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          queued
              ? '${r['item']} ($qtyText ${r['unit']}) is saved on this phone. '
                    'It will be sent to the DMC automatically when you are back online.'
              : 'Your request for ${r['item']} ($qtyText ${r['unit']}) was sent to the DMC. '
                    'It is now PENDING - the truck card on the Supplies page shows its status.',
          style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0B101D,
      ), // Dark Navy Background matching Figma
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
          selectedItemColor: const Color(
            0xFFFF5252,
          ), // Active top accent highlight
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
              icon: const Icon(Icons.settings),
              label: 'Settings',
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
        CampCapacityCard(
          controller: _controller,
          onRequestSupply: (item) => _showRequestSupplyDialog(item: item),
        ),
      ],
    );
  }

  // --- TAB 1: SUPPLIES (Image 2 frame2) ---
  Widget _buildSuppliesTab() {
    final items = _controller.filteredInventory;
    final shipment = _controller.incomingShipment;
    final req = _controller.activeRequest;
    final status = (req?['status'] ?? '')
        .toString(); // '' | pending | dispatched | arrived
    final hasRequest = req != null;
    final onTheWay = status == 'dispatched';
    final arrived = status == 'arrived';
    final isPending = status == 'pending';

    // While a supply request is open, the truck card follows it:
    // PENDING (waiting for the DMC) -> ON THE WAY (driver assigned) -> ARRIVED.
    String reqText() {
      final q = req?['quantityRequested'];
      final qText = q is num
          ? (q == q.roundToDouble() ? q.round().toString() : q.toString())
          : '';
      return '${req?['itemName'] ?? 'Supply'} - $qText ${req?['unit'] ?? ''}'
          .trim();
    }

    final driverName = (req?['driverName'] ?? '').toString();
    final driverPhone = hasRequest
        ? (req['driverPhone'] ?? '').toString()
        : shipment['driverPhone'] as String;

    String cardTitle = shipment['title'] as String;
    String cardSubtitle = shipment['subtitle'] as String;
    String cardBadge = shipment['eta'] as String;
    double? cardProgress = shipment['progress'] as double;
    Color accent = const Color(0xFF30D158);
    Color accentBg = const Color(0xFF063327);
    IconData cardIcon = Icons.local_shipping_outlined;

    if (isPending) {
      cardTitle = 'Supply Request';
      cardSubtitle = 'Waiting for DMC to assign a truck - ${reqText()}';
      cardBadge = 'PENDING';
      cardProgress = null;
      accent = const Color(0xFFFF9F0A);
      accentBg = const Color(0xFF382C1B);
      cardIcon = Icons.hourglass_top;
    } else if (onTheWay) {
      cardTitle = 'Truck on the way';
      cardSubtitle = 'Driver: $driverName - ${reqText()}';
      cardBadge = 'ON THE WAY';
      cardProgress = 0.65;
      accent = const Color(0xFF448AFF);
      accentBg = const Color(0xFF1B2A4A);
    } else if (arrived) {
      cardTitle = 'Truck arrived';
      cardSubtitle =
          'Driver: $driverName - ${reqText()}. Confirm when unloaded.';
      cardBadge = 'ARRIVED';
      cardProgress = 1.0;
      cardIcon = Icons.check_circle_outline;
    }

    // Call is possible when there is a driver number to call.
    final canCall = driverPhone.isNotEmpty && !isPending;
    // Restock can be confirmed after arrival (or for the demo convoy).
    final canRestock = hasRequest
        ? arrived
        : !(shipment['isRestocked'] as bool);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header: Title + clear action buttons
        const Text(
          'RATION & MEDICAL LOG',
          style: TextStyle(
            color: Color(0xFF7E8B9B),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF5252)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _showAddStockDialog,
                icon: const Icon(Icons.add, color: Color(0xFFFF5252), size: 18),
                label: const Text(
                  'ADD ITEM',
                  style: TextStyle(
                    color: Color(0xFFFF5252),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _showRequestSupplyDialog(),
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text(
                  'REQUEST SUPPLY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
              _buildSupplyFilterChip(
                'All',
                'All (18)',
                _controller.selectedSupplyFilter == 'All',
              ),
              _buildSupplyFilterChip(
                'Depleted',
                'Depleted (2)',
                _controller.selectedSupplyFilter == 'Depleted',
                outlineColor: const Color(0xFFFF3B30),
              ),
              _buildSupplyFilterChip(
                'Low',
                'Low (3)',
                _controller.selectedSupplyFilter == 'Low',
                outlineColor: const Color(0xFFFF9F0A),
              ),
              _buildSupplyFilterChip(
                'Adequate',
                'Adequate (13)',
                _controller.selectedSupplyFilter == 'Adequate',
                outlineColor: const Color(0xFF1E283D),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stock Items List
        ...items.map((item) {
          // Swipe left  -> mark EMPTY, swipe right -> mark LOW (M3-06).
          // The card stays in the list; its colour/badge updates instead.
          return Dismissible(
            key: ValueKey('supply_${item.id}'),
            background: _buildSwipeBackground(
              alignment: Alignment.centerLeft,
              color: const Color(0xFFFF9F0A),
              icon: Icons.trending_down,
              label: 'LOW',
            ),
            secondaryBackground: _buildSwipeBackground(
              alignment: Alignment.centerRight,
              color: const Color(0xFFFF3B30),
              icon: Icons.remove_shopping_cart_outlined,
              label: 'EMPTY',
            ),
            confirmDismiss: (direction) async {
              final isEmpty = direction == DismissDirection.endToStart;
              final previousQty = isEmpty
                  ? _controller.markItemEmpty(item.id)
                  : _controller.markItemLow(item.id);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      isEmpty
                          ? '${item.name} marked EMPTY'
                          : '${item.name} marked LOW',
                    ),
                    duration: const Duration(
                      seconds: 30,
                    ), // auto-hide after 30 s
                    persist:
                        false, // keep the timer even though there is an action
                    showCloseIcon: true, // X button to close it at once
                    closeIconColor: Colors.white,
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () =>
                          _controller.restoreItemQuantity(item.id, previousQty),
                    ),
                  ),
                );
              return false; // keep the card in place
            },
            child: SupplyItemTile(
              item: item,
              onQuantityChanged: (delta) =>
                  _controller.updateStockQuantity(item.id, delta),
            ),
          );
        }),

        const SizedBox(height: 20),

        // Incoming Shipment Tracking Tile (Matching Image 2 frame2).
        // Hidden after the restock is confirmed; a new request brings it back.
        if (_controller.showTruckCard)
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
                            color: accentBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(cardIcon, color: accent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cardTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: 170,
                              child: Text(
                                cardSubtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF7E8B9B),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cardBadge,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: cardProgress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF1E283D),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: canCall
                            ? () => _callDriver(driverPhone)
                            : null,
                        icon: const Icon(
                          Icons.phone_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: const Text(
                          'Call Driver',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canRestock
                              ? Colors.white
                              : Colors.grey,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: canRestock
                            ? () {
                                _controller.confirmRestock();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Restock confirmed. Stock updated.',
                                    ),
                                    backgroundColor: Color(0xFF30D158),
                                    showCloseIcon: true,
                                  ),
                                );
                              }
                            : null,
                        child: Text(
                          (!hasRequest && (shipment['isRestocked'] as bool))
                              ? 'Restocked'
                              : 'Confirm Restock',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),
        SupplyRequestsList(campId: _controller.campId),
      ],
    );
  }

  /// Coloured strip revealed behind a supply card while it is being swiped.
  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // same gap as SupplyItemTile
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the phone dialler with the shipment driver's number (M3-09).
  Future<void> _callDriver(String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not call $phone')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text('Could not call $phone')));
    }
  }

  /// Sends depleted items to the DMC as an urgent resupply request (M3-08).
  Future<void> _dispatchToDmc() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await _controller.sendUrgentDispatch();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'No depleted items to dispatch right now.'
                : 'Urgent resupply request for $count item(s) sent to the DMC.',
          ),
          backgroundColor: count == 0 ? null : const Color(0xFF30D158),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Dispatch failed: $e'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }

  Widget _buildSupplyFilterChip(
    String value,
    String label,
    bool isSelected, {
    Color? outlineColor,
  }) {
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
              color: isSelected
                  ? Colors.white
                  : (outlineColor ?? const Color(0xFF1E283D)),
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),

        // Live broadcast warnings sent by the admin
        const _BroadcastWarningsSection(),

        // Alert Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAlertFilterChip(
                'All',
                'All 12',
                _controller.selectedAlertFilter == 'All',
                activeColor: const Color(0xFFFF3B30),
              ),
              _buildAlertFilterChip(
                'Critical',
                'Critical 3',
                _controller.selectedAlertFilter == 'Critical',
              ),
              _buildAlertFilterChip(
                'Low Stock',
                'Low Stock 5',
                _controller.selectedAlertFilter == 'Low Stock',
              ),
              _buildAlertFilterChip(
                'Logs',
                'Logs 4',
                _controller.selectedAlertFilter == 'Logs',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          'TODAY',
          style: TextStyle(
            color: Color(0xFF7E8B9B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
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
              border: Border.all(
                color: cardBorderColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                alert['time'],
                                style: const TextStyle(
                                  color: Color(0xFF63738A),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert['subtitle'],
                            style: const TextStyle(
                              color: Color(0xFF8E9BAE),
                              fontSize: 11,
                            ),
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
                          backgroundColor: isLogs
                              ? const Color(0xFF30D158)
                              : const Color(0xFFFF3B30),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          // "DISPATCH SUPPLY" really notifies the DMC (M3-08 / FR12);
                          // the other actions keep their existing behaviour.
                          if (alert['actionText'] == 'DISPATCH SUPPLY') {
                            _dispatchToDmc();
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Triggered: ${alert['actionText']}',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          alert['actionText'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E283D),
                          foregroundColor: const Color(0xFF8E9BAE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _controller.dismissAlert(alert['id']),
                        child: const Text(
                          'Dismiss',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
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

  Widget _buildAlertFilterChip(
    String value,
    String label,
    bool isSelected, {
    Color? activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _controller.setAlertFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (activeColor ?? const Color(0xFF1E283D))
                : const Color(0xFF131A2A),
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
              LeaderAvatar(
                name: _controller.leaderName,
                photoUrl: _controller.leaderPhotoUrl,
                size: 72,
              ),
              const SizedBox(height: 12),
              Text(
                _controller.leaderName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Relief Team Lead - ${_controller.campName}',
                style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                      style: TextStyle(
                        color: Color(0xFF30D158),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                style: TextStyle(
                  color: Color(0xFF7E8B9B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PersonalInformationScreen(),
                    ),
                  );
                },
                child: _buildAccountRow(
                  Icons.person_outline,
                  'Personal Information',
                  'Name, photo, contact details',
                ),
              ),
              const Divider(color: Color(0xFF1E283D), height: 16),
              _buildAccountRow(
                Icons.night_shelter_outlined,
                'Assigned Shelters',
                'Camp Nēraya, Camp Dawn Ridge',
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await SessionService.clear();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ResponderLoginScreen()),
                (route) => false,
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF63738A),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow(
    IconData icon,
    String title,
    String subtitle, {
    String? badgeText,
  }) {
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
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
              style: const TextStyle(
                color: Color(0xFF30D158),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          const Icon(Icons.chevron_right, color: Color(0xFF5E6D82), size: 18),
      ],
    );
  }

  // --- TAB 4: TEAM / COMMUNITY CHAT (live chat between all camp leaders) ---
  Widget _buildTeamTab() {
    return LeadersChatPanel(controller: _controller);
  }
}

/// Live list of the warnings an admin broadcasts (Firestore `warnings`).
/// Resolved warnings are deleted by the admin, so they disappear here too.
class _BroadcastWarningsSection extends StatefulWidget {
  const _BroadcastWarningsSection();

  @override
  State<_BroadcastWarningsSection> createState() =>
      _BroadcastWarningsSectionState();
}

class _BroadcastWarningsSectionState extends State<_BroadcastWarningsSection> {
  /// Warnings this person cleared. Stored on this device only; the warning
  /// itself stays in Firestore for everyone else.
  Set<String> _cleared = {};

  String get _key {
    final email = ResponderController().currentUser?.email ?? 'anon';
    return 'cleared_warnings_${email.toLowerCase().trim()}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getStringList(_key) ?? const <String>[];
      if (mounted) setState(() => _cleared = saved.toSet());
    } catch (_) {}
  }

  Future<void> _clear(Iterable<String> ids) async {
    setState(() => _cleared = {..._cleared, ...ids});
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_key, _cleared.toList());
    } catch (_) {}
  }

  static const Color _card = Color(0xFF131A2A);
  static const Color _muted = Color(0xFF8E9BAE);

  static Color _color(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFF3B30);
      case 'warning':
        return const Color(0xFFFF9F0A);
      default:
        return const Color(0xFFFFD60A);
    }
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('warnings')
          .orderBy('issuedTimestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        final docs =
            (snap.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .where((d) => !_cleared.contains(d.id))
                .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  color: Color(0xFFFF3B30),
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'BROADCAST WARNINGS FROM ADMIN',
                  style: TextStyle(
                    color: Color(0xFF7E8B9B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                if (docs.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${docs.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (docs.isNotEmpty)
                  GestureDetector(
                    onTap: () => _clear(docs.map((d) => d.id)),
                    child: const Text(
                      'CLEAR ALL',
                      style: TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (snap.hasError)
              const Text(
                'Could not load warnings.',
                style: TextStyle(color: _muted, fontSize: 12),
              )
            else if (docs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E283D)),
                ),
                child: const Text(
                  'No active broadcast warnings.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              )
            else
              ...docs.map((d) => _tile(d.id, WarningAlert.fromDoc(d))),
            const SizedBox(height: 18),
          ],
        );
      },
    );
  }

  Widget _tile(String id, WarningAlert w) {
    final color = _color(w.severity);
    final where = [
      w.locationZone,
      w.district,
    ].where((e) => e.trim().isNotEmpty).join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color),
                ),
                child: Text(
                  w.severity.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  w.hazardType.isEmpty ? 'Flood warning' : w.hazardType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _ago(w.issuedTimestamp),
                style: const TextStyle(color: Color(0xFF63738A), fontSize: 10),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _clear([id]),
                child: const Icon(Icons.close, color: _muted, size: 18),
              ),
            ],
          ),
          if (where.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place_outlined, color: _muted, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    where,
                    style: const TextStyle(color: _muted, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Water level ${w.waterLevelMeters.toStringAsFixed(1)} m  ·  '
            'Rainfall ${w.rainfallMm.toStringAsFixed(0)} mm',
            style: const TextStyle(color: _muted, fontSize: 11.5),
          ),
          if (w.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              w.description,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }
}
