import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collaboration_request_model.dart';
import '../services/firestore_service.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final FirestoreService firestoreService = FirestoreService();

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collaboration Requests')),
        body: const Center(child: Text('Please log in to view your requests.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages & Requests'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<List<CollaborationRequestModel>>(
        stream: firestoreService.streamIncomingRequests(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading requests: ${snapshot.error}'),
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No Requests Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When developers find your projects and send collaboration requests, they will appear here in real-time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final isPending = req.status == 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: req.senderAvatarUrl != null
                                ? NetworkImage(req.senderAvatarUrl!)
                                : null,
                            child: req.senderAvatarUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.senderName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Project: ${req.projectName}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: req.status == 'accepted'
                                  ? Colors.green[50]
                                  : req.status == 'declined'
                                      ? Colors.red[50]
                                      : Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: req.status == 'accepted'
                                    ? Colors.green
                                    : req.status == 'declined'
                                        ? Colors.red
                                        : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (req.lastMessage != null && req.lastMessage!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          req.lastMessage!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      if (isPending) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  firestoreService.updateRequestStatus(req.id, 'declined');
                                },
                                child: const Text('Decline', style: TextStyle(color: Colors.red)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF)),
                                onPressed: () {
                                  firestoreService.updateRequestStatus(req.id, 'accepted');
                                },
                                child: const Text('Accept', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
