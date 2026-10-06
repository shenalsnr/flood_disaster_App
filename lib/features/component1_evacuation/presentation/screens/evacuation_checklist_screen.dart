import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Evacuation Checklist Screen — Component 1: Early Warning & Evacuation
// ---------------------------------------------------------------------------
// Personalized go-bag tracker. All state is local (StatefulWidget).
// Replace _items list with a Firebase stream / Firestore collection later.
// ---------------------------------------------------------------------------

// Model — swap for a Firestore-backed model when backend is ready
class ChecklistItem {
  final String id;
  String name;
  bool isPacked;

  ChecklistItem({
    required this.id,
    required this.name,
    this.isPacked = false,
  });
}

class EvacuationChecklistScreen extends StatefulWidget {
  const EvacuationChecklistScreen({super.key});

  @override
  State<EvacuationChecklistScreen> createState() =>
      _EvacuationChecklistScreenState();
}

class _EvacuationChecklistScreenState
    extends State<EvacuationChecklistScreen> {
  // --- Mock data (replace with Firestore stream later) ---
  final List<ChecklistItem> _items = [
    ChecklistItem(id: '1', name: 'Water (3-day supply)'),
    ChecklistItem(id: '2', name: 'First Aid Kit'),
    ChecklistItem(id: '3', name: 'Flashlight & Batteries'),
    ChecklistItem(id: '4', name: 'Emergency Cash'),
    ChecklistItem(id: '5', name: 'Medications (7-day supply)'),
    ChecklistItem(id: '6', name: 'Important Documents (NIC, Passport)'),
    ChecklistItem(id: '7', name: 'Whistle / Signal Device'),
    ChecklistItem(id: '8', name: 'Warm Blanket', isPacked: true),
    ChecklistItem(id: '9', name: 'Phone Charger & Power Bank', isPacked: true),
  ];

  final TextEditingController _addController = TextEditingController();
  int _uniqueIdCounter = 100;

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  // ── CRUD Operations (will call Firestore later) ──────────────────────────

  void _addItem() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items.add(
        ChecklistItem(
          id: (_uniqueIdCounter++).toString(),
          name: text,
        ),
      );
      _addController.clear();
    });
  }

  void _togglePacked(ChecklistItem item) {
    setState(() {
      item.isPacked = !item.isPacked;
    });
  }

  void _deleteItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
  }

  // ── Computed stats ───────────────────────────────────────────────────────
  int get _packedCount => _items.where((i) => i.isPacked).length;
  double get _progress =>
      _items.isEmpty ? 0 : _packedCount / _items.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Go-Bag Checklist',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_packedCount / ${_items.length}',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Progress Header ──────────────────────────────────────────────
          _ProgressHeader(progress: _progress, packedCount: _packedCount, total: _items.length),

          // ── Add Item Input ───────────────────────────────────────────────
          _AddItemField(
            controller: _addController,
            onAdd: _addItem,
          ),

          // ── Checklist ────────────────────────────────────────────────────
          Expanded(
            child: _items.isEmpty
                ? _EmptyState(
                    icon: Icons.checklist_rounded,
                    message: 'Your checklist is empty.\nAdd items above.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _ChecklistItemTile(
                        key: ValueKey(item.id),
                        item: item,
                        onToggle: () => _togglePacked(item),
                        onDelete: () => _deleteItem(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ProgressHeader extends StatelessWidget {
  final double progress;
  final int packedCount;
  final int total;

  const _ProgressHeader({
    required this.progress,
    required this.packedCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: const Color(0xFF141414),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pct == 100
                    ? '✅ Go-Bag Ready!'
                    : 'Pack your essentials before evacuating',
                style: TextStyle(
                  color: pct == 100 ? const Color(0xFF00E676) : Colors.white70,
                  fontSize: 13,
                  fontWeight: pct == 100 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? const Color(0xFF00E676) : const Color(0xFFFFD740),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddItemField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _AddItemField({required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('checklist_add_field'),
              controller: controller,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Add new item (e.g. Rain coat)...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF2A2A2A), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF00E676), width: 1.5),
                ),
              ),
              onSubmitted: (_) => onAdd(),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            height: 52,
            child: ElevatedButton(
              key: const Key('checklist_add_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onAdd,
              child: const Icon(Icons.add_rounded, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismissible_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFB71C1C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_sweep_rounded,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        // Optional: confirm before delete
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: item.isPacked
              ? const Color(0xFF0D1F0D)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isPacked
                ? const Color(0xFF00E676).withValues(alpha: 0.4)
                : const Color(0xFF2A2A2A),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          minVerticalPadding: 12,
          leading: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isPacked
                    ? const Color(0xFF00E676)
                    : Colors.transparent,
                border: Border.all(
                  color: item.isPacked
                      ? const Color(0xFF00E676)
                      : Colors.white38,
                  width: 2,
                ),
              ),
              child: item.isPacked
                  ? const Icon(Icons.check_rounded,
                      color: Colors.black, size: 18)
                  : null,
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              color: item.isPacked ? Colors.white38 : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              decoration:
                  item.isPacked ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: Colors.white38,
            ),
          ),
          subtitle: item.isPacked
              ? const Text('Packed ✓',
                  style: TextStyle(color: Color(0xFF00E676), fontSize: 11))
              : null,
          trailing: const Icon(Icons.swipe_left_rounded,
              color: Colors.white24, size: 18),
          onTap: onToggle,
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
          Icon(icon, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
