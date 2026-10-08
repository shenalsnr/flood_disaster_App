import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/services/firestore_service.dart';
import '../controllers/relief_tracking_controller.dart';

/// Live "Community Chat" shared by all camp leaders (Team tab).
///
/// Messages are stored in the Firestore collection `leaderChat`, so a message
/// sent from one leader's device appears on every other leader's device.
class LeadersChatPanel extends StatefulWidget {
  final ReliefTrackingController controller;

  const LeadersChatPanel({super.key, required this.controller});

  @override
  State<LeadersChatPanel> createState() => _LeadersChatPanelState();
}

class _LeadersChatPanelState extends State<LeadersChatPanel> {
  final TextEditingController _textController = TextEditingController();
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  String? _initError;

  @override
  void initState() {
    super.initState();
    try {
      _stream = FirestoreService.instance.streamLeaderChat();
    } catch (e) {
      _initError = '$e';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final c = widget.controller;
    _textController.clear();
    try {
      await FirestoreService.instance.sendLeaderChatMessage(
        senderId: c.chatClientId,
        senderName: c.chatName,
        campName: c.chatCamp,
        text: text,
      );
    } catch (e) {
      if (!mounted) return;
      _textController.text = text; // give the text back so nothing is lost
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message not sent: $e'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }

  Future<void> _editIdentity() async {
    final c = widget.controller;
    final nameCtrl = TextEditingController(text: c.chatName);
    final campCtrl = TextEditingController(text: c.chatCamp);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A2A),
        title: const Text(
          'Your chat name',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Other camp leaders will see this name next to your messages.',
              style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 12),
            ),
            const SizedBox(height: 14),
            _dialogField(nameCtrl, 'Your name'),
            const SizedBox(height: 10),
            _dialogField(campCtrl, 'Your camp'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E9BAE))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final name = nameCtrl.text.trim();
      final camp = campCtrl.text.trim();
      if (name.isNotEmpty) {
        c.setChatIdentity(name, camp.isEmpty ? c.chatCamp : camp);
        if (mounted) setState(() {});
      }
    }
  }

  Widget _dialogField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0B101D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E283D)),
        ),
      ),
    );
  }

  String _formatTime(dynamic ts) {
    // A message you just sent has no server time yet: show the current time.
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          color: const Color(0xFF131A2A),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF1F2C46),
                child: Icon(Icons.people, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Chat',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '● Live • All camp leaders',
                      style: TextStyle(color: Color(0xFF30D158), fontSize: 10),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _editIdentity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      c.chatName,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Color(0xFFFF5252), size: 11),
                        SizedBox(width: 3),
                        Text('Change name', style: TextStyle(color: Color(0xFFFF5252), fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(child: _buildMessages()),

        // Input bar
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF131A2A),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Message the team...',
                    hintStyle: TextStyle(color: Color(0xFF5E6D82), fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _send,
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFFF5252),
                  child: Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessages() {
    if (_stream == null) {
      return _centerNote('Chat is unavailable right now.\n$_initError');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _centerNote(
            'Chat is unavailable.\nCheck the Firestore rules for "leaderChat".\n${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _centerNote('No messages yet.\nSay hello to the other camp leaders.');
        }

        return ListView.builder(
          reverse: true, // newest message stays at the bottom
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data();
            final isSelf = d['senderId'] == widget.controller.chatClientId;
            final senderName = (d['senderName'] ?? 'Leader').toString();
            final campName = (d['campName'] ?? '').toString();
            final label = isSelf
                ? 'You'
                : (campName.isEmpty ? senderName : '$senderName • $campName');
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildBubble(
                sender: label,
                text: (d['text'] ?? '').toString(),
                time: _formatTime(d['createdAt']),
                isSelf: isSelf,
              ),
            );
          },
        );
      },
    );
  }

  Widget _centerNote(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7E8B9B), fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildBubble({
    required String sender,
    required String text,
    required String time,
    required bool isSelf,
  }) {
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
            Text(
              sender,
              style: TextStyle(
                color: isSelf ? const Color(0xFF448AFF) : const Color(0xFF30D158),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
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
