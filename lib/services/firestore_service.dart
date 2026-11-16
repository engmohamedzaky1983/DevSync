import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/developer_model.dart';
import '../models/project_model.dart';
import '../models/collaboration_request_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Save or update developer profile
  Future<void> saveDeveloperProfile(DeveloperModel developer) async {
    await _db
        .collection('users')
        .doc(developer.id)
        .set(developer.toMap(), SetOptions(merge: true));
  }

  // 2. Fetch developer profile
  Future<DeveloperModel?> getDeveloperProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return DeveloperModel.fromMap(doc.data()!, docId: doc.id);
    }
    return null;
  }

  // 3. Fetch real developers from Firestore (optionally filter by track and exclude current user)
  Future<List<DeveloperModel>> getDevelopers({String? excludeUid, String? developmentTrack}) async {
    Query query = _db.collection('users');

    if (developmentTrack != null && developmentTrack.isNotEmpty && developmentTrack != 'All') {
      query = query.where('developmentTrack', isEqualTo: developmentTrack);
    }

    final querySnapshot = await query.get();
    final List<DeveloperModel> list = [];

    for (var doc in querySnapshot.docs) {
      if (doc.id == excludeUid) continue;
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        list.add(DeveloperModel.fromMap(data, docId: doc.id));
      }
    }
    return list;
  }

  // 4. Create a new project & return its generated document ID
  Future<String> createProject(ProjectModel project) async {
    final docRef = _db.collection('projects').doc();
    final projectWithId = ProjectModel(
      id: docRef.id,
      ownerId: project.ownerId,
      projectName: project.projectName,
      description: project.description,
      developmentTrack: project.developmentTrack,
      languagesAndTools: project.languagesAndTools,
      frameworksAndPlatforms: project.frameworksAndPlatforms,
      projectSize: project.projectSize,
      dailyHours: project.dailyHours,
      projectDuration: project.projectDuration,
      requiredDevelopers: project.requiredDevelopers,
      experienceLevel: project.experienceLevel,
      availability: project.availability,
      createdAt: project.createdAt,
    );
    await docRef.set(projectWithId.toMap());
    return docRef.id;
  }

  // 5. Send a collaboration request
  Future<void> sendCollaborationRequest(CollaborationRequestModel request) async {
    final docRef = _db.collection('requests').doc();
    await docRef.set({
      ...request.toMap(),
      'id': docRef.id,
    });
  }

  // 6. Stream incoming requests for the current user
  Stream<List<CollaborationRequestModel>> streamIncomingRequests(String userId) {
    return _db
        .collection('requests')
        .where('receiverId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CollaborationRequestModel.fromMap(doc.data(), docId: doc.id))
            .toList());
  }

  // 7. Update status of a collaboration request (e.g. accepted, declined)
  Future<void> updateRequestStatus(String requestId, String status) async {
    await _db.collection('requests').doc(requestId).update({
      'status': status,
    });
  }
}
