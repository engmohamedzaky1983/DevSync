import 'package:equatable/equatable.dart';

class ProjectModel extends Equatable {
  final String id;
  final String ownerId;
  final String projectName;
  final String description;
  final String developmentTrack;
  final List<String> languagesAndTools;
  final List<String> frameworksAndPlatforms;
  final String projectSize;
  final String dailyHours;
  final String projectDuration;
  final int requiredDevelopers;
  final String experienceLevel;
  final String availability;
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.ownerId,
    required this.projectName,
    required this.description,
    required this.developmentTrack,
    this.languagesAndTools = const [],
    this.frameworksAndPlatforms = const [],
    this.projectSize = 'Small',
    this.dailyHours = '3-5',
    this.projectDuration = 'Weeks',
    this.requiredDevelopers = 2,
    this.experienceLevel = 'Mid-level',
    this.availability = 'Part-time',
    required this.createdAt,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ProjectModel(
      id: docId ?? map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      projectName: map['projectName'] ?? '',
      description: map['description'] ?? '',
      developmentTrack: map['developmentTrack'] ?? 'AI / Machine Learning',
      languagesAndTools: List<String>.from(map['languagesAndTools'] ?? []),
      frameworksAndPlatforms: List<String>.from(map['frameworksAndPlatforms'] ?? []),
      projectSize: map['projectSize'] ?? 'Small',
      dailyHours: map['dailyHours'] ?? '3-5',
      projectDuration: map['projectDuration'] ?? 'Weeks',
      requiredDevelopers: map['requiredDevelopers'] ?? 2,
      experienceLevel: map['experienceLevel'] ?? 'Mid-level',
      availability: map['availability'] ?? 'Part-time',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'projectName': projectName,
      'description': description,
      'developmentTrack': developmentTrack,
      'languagesAndTools': languagesAndTools,
      'frameworksAndPlatforms': frameworksAndPlatforms,
      'projectSize': projectSize,
      'dailyHours': dailyHours,
      'projectDuration': projectDuration,
      'requiredDevelopers': requiredDevelopers,
      'experienceLevel': experienceLevel,
      'availability': availability,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    projectName,
    description,
    developmentTrack,
    languagesAndTools,
    frameworksAndPlatforms,
    projectSize,
    dailyHours,
  ];
}