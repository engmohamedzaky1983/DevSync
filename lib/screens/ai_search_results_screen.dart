import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/developer_model.dart';
import '../models/project_model.dart';
import '../models/collaboration_request_model.dart';
import '../services/firestore_service.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'project_form_screen.dart';

class AiSearchResultsScreen extends StatefulWidget {
  final ProjectModel? project;

  const AiSearchResultsScreen({super.key, this.project});

  @override
  State<AiSearchResultsScreen> createState() => _AiSearchResultsScreenState();
}

class _AiSearchResultsScreenState extends State<AiSearchResultsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<DeveloperModel> _developers = [];
  bool _isLoading = true;
  final Set<String> _sentRequests = {};
  final int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
      );
    } else if (index == 2) {
      // Already on AI Search screen
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MessagesScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDevelopers();
  }

  Future<void> _loadDevelopers() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    try {
      final list = await _firestoreService.getDevelopers(
        excludeUid: currentUserId,
        developmentTrack: widget.project?.developmentTrack,
      );
      if (mounted) {
        setState(() {
          _developers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching developers from Firestore: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendRequest(DeveloperModel developer) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final request = CollaborationRequestModel(
        id: '',
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Developer',
        senderAvatarUrl: currentUser.photoURL,
        receiverId: developer.id,
        projectId: widget.project?.id ?? '',
        projectName: widget.project?.projectName ?? 'Open-Source Collaboration',
        status: 'pending',
        lastMessage: 'I would like to collaborate on ${widget.project?.projectName ?? "this project"}!',
        timestamp: DateTime.now(),
      );

      await _firestoreService.sendCollaborationRequest(request);

      if (mounted) {
        setState(() {
          _sentRequests.add(developer.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collaboration request sent to ${developer.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matched Developers'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_unread_outlined),
            tooltip: 'View Requests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _developers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No Other Developers Registered Yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.project != null
                              ? 'Your project "${widget.project!.projectName}" has been created in Firestore. As other developers register in "${widget.project!.developmentTrack}", they will appear here.'
                              : 'As developers register on DevSync, they will appear here.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.message, color: Colors.white),
                          label: const Text('Check My Messages & Requests', style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MessagesScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _developers.length,
                  itemBuilder: (context, index) {
                    final dev = _developers[index];
                    final isSent = _sentRequests.contains(dev.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: dev.avatarUrl != null && dev.avatarUrl!.isNotEmpty
                                      ? NetworkImage(dev.avatarUrl!)
                                      : null,
                                  child: dev.avatarUrl == null || dev.avatarUrl!.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dev.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        '${dev.developmentTrack} • ${dev.experience}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (dev.githubUrl.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.code),
                                    tooltip: dev.githubUrl,
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('GitHub: ${dev.githubUrl}')),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            if (dev.skills.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: dev.skills
                                    .map(
                                      (skill) => Chip(
                                        label: Text(skill, style: const TextStyle(fontSize: 11)),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSent ? Colors.grey : const Color(0xFF0066FF),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(isSent ? Icons.check : Icons.send, color: Colors.white, size: 18),
                                label: Text(
                                  isSent ? 'Request Sent' : 'Send Collaboration Request',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onPressed: isSent ? null : () => _sendRequest(dev),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0066FF),
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'AI Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
          ],
        ),
      ),
    );
  }
}
