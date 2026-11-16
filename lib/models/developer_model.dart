import 'package:equatable/equatable.dart';

class DeveloperModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String developmentTrack;
  final String experience;
  final int projectsWorkedOn;
  final String githubUrl;
  final String? portfolioUrl;
  final String? linkedinUrl;
  final String? avatarUrl;
  final List<String> skills;
  final int? matchScore; // Populated by AI search results (e.g., 92)
  final String? availability;
  final String? fcmToken;
  final bool isVerified;

  const DeveloperModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'Developer',
    this.developmentTrack = 'Full Stack',
    this.experience = '1-2 years',
    this.projectsWorkedOn = 0,
    required this.githubUrl,
    this.portfolioUrl,
    this.linkedinUrl,
    this.avatarUrl,
    this.skills = const [],
    this.matchScore,
    this.availability,
    this.fcmToken,
    this.isVerified = false,
  });

  // Parse from Firestore document or AI Search JSON response
  factory DeveloperModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return DeveloperModel(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? 'Unknown Developer',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Developer',
      developmentTrack: map['developmentTrack'] ?? 'Full Stack',
      experience: map['experience'] ?? '1-2 years',
      projectsWorkedOn: map['projectsWorkedOn'] ?? 0,
      githubUrl: map['githubUrl'] ?? '',
      portfolioUrl: map['portfolioUrl'],
      linkedinUrl: map['linkedinUrl'],
      avatarUrl: map['avatarUrl'],
      skills: List<String>.from(map['skills'] ?? []),
      matchScore: map['matchScore'],
      availability: map['availability'],
      fcmToken: map['fcmToken'],
      isVerified: map['isVerified'] ?? false,
    );
  }

  // Convert to Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'developmentTrack': developmentTrack,
      'experience': experience,
      'projectsWorkedOn': projectsWorkedOn,
      'githubUrl': githubUrl,
      'portfolioUrl': portfolioUrl,
      'linkedinUrl': linkedinUrl,
      'avatarUrl': avatarUrl,
      'skills': skills,
      'availability': availability,
      'fcmToken': fcmToken,
      'isVerified': isVerified,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    role,
    developmentTrack,
    experience,
    projectsWorkedOn,
    githubUrl,
    skills,
    matchScore,
  ];
}