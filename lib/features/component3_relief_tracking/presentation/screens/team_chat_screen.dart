import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';
import '../../domain/services/shelter_relief_service.dart';
import '../../data/models/chat_message_model.dart';

class TeamChatScreen extends StatefulWidget {
  const TeamChatScreen({super.key});

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  final ShelterReliefService _service = ShelterReliefService.instance;
  final TextEditingController _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdate);
  }
  
  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    _msgCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    _service.addChatMessage(
      ChatMessageModel(
        id: now.millisecondsSinceEpoch.toString(),
        senderName: 'You',
        senderCampId: _service.selectedShelterId ?? 'myCamp',
        text: text,
        timestamp: timeStr,
        isSelf: true,
        status: MessageStatus.sent,
      ),
    );
    
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _service.chatMessages;

    return Scaffold(
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      appBar: AppBar(
        backgroundColor: ShelterTheme.backgroundDeepNavy,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: ShelterTheme.surfaceLightNavy,
            child: const Icon(Icons.group, color: Colors.white, size: 18),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Community Chat', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('12 online - Inter-Camp Comms', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Pinned Message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: ShelterTheme.surfaceDarkNavy,
            child: Row(
              children: [
                const Icon(Icons.push_pin, color: ShelterTheme.primaryActionOrange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('PINNED', style: TextStyle(color: ShelterTheme.primaryActionOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('Coordination channel for Camp Leaders only.', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(child: Text('TODAY', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold))),
                  );
                }
                final msg = messages[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildChatBubble(msg.senderName, msg.text, msg.timestamp, msg.isSelf, msg.avatarInitials),
                );
              },
            ),
          ),
          
          // INPUT AREA
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: ShelterTheme.surfaceDarkNavy,
              border: Border(top: BorderSide(color: ShelterTheme.surfaceLightNavy)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: ShelterTheme.textMuted),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: ShelterTheme.backgroundDeepNavy,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: ShelterTheme.surfaceLightNavy),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Message the team...',
                        hintStyle: TextStyle(color: ShelterTheme.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: ShelterTheme.primaryActionOrange,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String sender, String message, String time, bool isMe, String? avatar) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: ShelterTheme.surfaceLightNavy,
            child: Text(avatar ?? sender[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(sender, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? ShelterTheme.primaryActionOrange.withValues(alpha: 0.15) : ShelterTheme.surfaceDarkNavy,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 16),
                  ),
                  border: Border.all(
                    color: isMe ? ShelterTheme.primaryActionOrange.withValues(alpha: 0.5) : ShelterTheme.surfaceLightNavy,
                  ),
                ),
                child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(time, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 10)),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, color: ShelterTheme.statusSafeGreen, size: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isMe) const SizedBox(width: 24),
      ],
    );
  }
}
