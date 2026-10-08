import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';

class TeamChatScreen extends StatelessWidget {
  const TeamChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            Text('12 online - Kolonnawa Zone 04', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12)),
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
                      Text('Water distribution at 3 PM — Gate B', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Center(child: Text('TODAY', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                _buildChatBubble('Nadeesha1', 'Water levels rising near Gate B. We need sandbags urgently.', '12:41', false, 'N'),
                const SizedBox(height: 16),
                _buildChatBubble('Priyala', 'Convoy 3 is 10 mins out with water + formula. Hang tight.', '12:42', false, 'P'),
                const SizedBox(height: 16),
                _buildSystemMessage('Dr. Rohan Silva joined the message'),
                const SizedBox(height: 16),
                _buildChatBubble('You', 'Copy. Redirecting volunteers to Gate B now. Keep me posted on the ETA.', '12:44', true, null),
                const SizedBox(height: 16),
                _buildChatBubble('Nadeesha1', 'Can DMC expedite this one?', '12:47', false, 'N'),
                const SizedBox(height: 16),
                _buildChatBubble('You', 'Escalating to DMC now. Dispatch PMIL0-042 is in.', '12:50', true, null),
              ],
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
                    child: const TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Message the team...',
                        hintStyle: TextStyle(color: ShelterTheme.textMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: ShelterTheme.primaryActionOrange,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ShelterTheme.surfaceDarkNavy,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 10)),
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
            child: Text(avatar ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
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
        if (isMe) const SizedBox(width: 24), // Spacer for self messages so they don't touch the edge
      ],
    );
  }
}
