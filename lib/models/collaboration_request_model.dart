import 'package:equatable/equatable.dart';

class CollaborationRequestModel extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String receiverId;
  final String projectId;
  final String projectName;
  final String status; // 'pending', 'accepted', 'declined'
  final String? lastMessage;
  final DateTime timestamp;

  const CollaborationRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.receiverId,
    required this.projectId,
    required this.projectName,
    this.status = 'pending',
    this.lastMessage,
    required this.timestamp,
  });

  factory CollaborationRequestModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return CollaborationRequestModel(
      id: docId ?? map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatarUrl: map['senderAvatarUrl'],
      receiverId: map['receiverId'] ?? '',
      projectId: map['projectId'] ?? '',
      projectName: map['projectName'] ?? '',
      status: map['status'] ?? 'pending',
      lastMessage: map['lastMessage'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'receiverId': receiverId,
      'projectId': projectId,
      'projectName': projectName,
      'status': status,
      'lastMessage': lastMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, senderId, receiverId, projectId, status, timestamp];
}