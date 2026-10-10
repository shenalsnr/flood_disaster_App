
enum MessageStatus { sent, delivered, read }

class ChatMessageModel {
  final String id;
  final String senderName;
  final String senderCampId;
  final String text;
  final String timestamp;
  final bool isSelf;
  final String? avatarInitials;
  final MessageStatus status;

  const ChatMessageModel({
    required this.id,
    required this.senderName,
    required this.senderCampId,
    required this.text,
    required this.timestamp,
    required this.isSelf,
    this.avatarInitials,
    required this.status,
  });
}
