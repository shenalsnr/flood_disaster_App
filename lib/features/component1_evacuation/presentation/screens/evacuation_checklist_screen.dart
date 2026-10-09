import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../../services/citizen_firestore_service.dart';

// Model — mapped from Firestore DocumentSnapshot
class ChecklistItem {
  final String id;
  String name;
  bool isPacked;

  ChecklistItem({
    required this.id,
    required this.name,
    this.isPacked = false,
  });

  factory ChecklistItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChecklistItem(
      id: doc.id,
      name: data['itemName'] ?? '',
      isPacked: data['isPacked'] ?? false,
    );
  }
}

class EvacuationChecklistScreen extends StatefulWidget {
  const EvacuationChecklistScreen({super.key});

  @override
  State<EvacuationChecklistScreen> createState() =>
      _EvacuationChecklistScreenState();
}

class _EvacuationChecklistScreenState
    extends State<EvacuationChecklistScreen> {
  final CitizenFirestoreService _firestoreService = CitizenFirestoreService();
  final TextEditingController _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  // ── CRUD Operations (Firestore) ──────────────────────────────────────────

  void _addItem() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    await _firestoreService.addChecklistItem(text);
    _addController.clear();
  }

  void _togglePacked(ChecklistItem item) {
    _firestoreService.toggleChecklistItem(item.id, item.isPacked);
  }

  void _deleteItem(String id) {
    _firestoreService.deleteChecklistItem(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: const Color(0xFF070B14).withValues(alpha: 0.7),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Go-Bag Checklist',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [Color(0xFF112240), Color(0xFF070B14)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getChecklistItems(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Error loading checklist',
                      style: TextStyle(color: Colors.red)),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E676)),
                );
              }

              final List<ChecklistItem> items = snapshot.data!.docs
                  .map((doc) => ChecklistItem.fromFirestore(doc))
                  .toList();

              final int packedCount = items.where((i) => i.isPacked).length;
              final double progress =
                  items.isEmpty ? 0 : packedCount / items.length;

              return Column(
                children: [
                  // ── Progress Header ──────────────────────────────────────────────
                  _PremiumProgressHeader(
                    progress: progress,
                    packedCount: packedCount,
                    total: items.length,
                  ),

                  // ── Add Item Input ───────────────────────────────────────────────
                  _PremiumAddItemField(
                    controller: _addController,
                    onAdd: _addItem,
                  ),

                  const SizedBox(height: 10),

                  // ── Checklist ────────────────────────────────────────────────────
                  Expanded(
                    child: items.isEmpty
                        ? const _EmptyState(
                            icon: Icons.backpack_rounded,
                            message:
                                'Your Go-Bag is empty.\nAdd essential items above.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            physics: const BouncingScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _PremiumChecklistItemTile(
                                key: ValueKey(item.id),
                                item: item,
                                onToggle: () => _togglePacked(item),
                                onDelete: () => _deleteItem(item.id),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium Sub-widgets
// ---------------------------------------------------------------------------

class _PremiumProgressHeader extends StatelessWidget {
  final double progress;
  final int packedCount;
  final int total;

  const _PremiumProgressHeader({
    required this.progress,
    required this.packedCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    final isComplete = pct == 100 && total > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isComplete
              ? const Color(0xFF00E676).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isComplete
                ? const Color(0xFF00E676).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isComplete ? 'Ready for Evacuation' : 'Packing Progress',
                    style: TextStyle(
                      color: isComplete ? const Color(0xFF00E676) : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$packedCount of $total items packed',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isComplete
                      ? const Color(0xFF00E676).withValues(alpha: 0.15)
                      : const Color(0xFF40C4FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    color: isComplete
                        ? const Color(0xFF00E676)
                        : const Color(0xFF40C4FF),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFF070B14),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? const Color(0xFF00E676) : const Color(0xFF40C4FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumAddItemField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _PremiumAddItemField({required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131B2B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                key: const Key('checklist_add_field'),
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Add new item (e.g. Flashlight)...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 15,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.black,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PremiumChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.isPacked
            ? const Color(0xFF00E676).withValues(alpha: 0.05)
            : const Color(0xFF131B2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPacked
              ? const Color(0xFF00E676).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: [
          if (!item.isPacked)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Animated Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: item.isPacked
                        ? const Color(0xFF00E676)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.isPacked
                          ? const Color(0xFF00E676)
                          : Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: item.isPacked
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: item.isPacked
                      ? const Icon(Icons.check_rounded,
                          color: Colors.black, size: 20)
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Item Name
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: item.isPacked
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: item.isPacked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: Colors.white.withValues(alpha: 0.4),
                      decorationThickness: 2,
                    ),
                    child: Text(item.name),
                  ),
                ),
                
                // Delete Button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFFF5252),
                      size: 20,
                    ),
                    tooltip: 'Delete Item',
                    onPressed: () {
                      // Haptic feedback or confirmation dialog can be added here
                      onDelete();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
