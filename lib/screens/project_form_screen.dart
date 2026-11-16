import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_model.dart';
import '../services/firestore_service.dart';
import 'ai_search_results_screen.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _toolsController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  String _selectedTrack = 'AI / Machine Learning';
  String _selectedSize = 'Small';
  String _dailyHours = '3-5';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _toolsController.dispose();
    super.dispose();
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first to create a project.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tools = _toolsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final project = ProjectModel(
        id: '',
        ownerId: user.uid,
        projectName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        developmentTrack: _selectedTrack,
        languagesAndTools: tools,
        projectSize: _selectedSize,
        dailyHours: _dailyHours,
        createdAt: DateTime.now(),
      );

      final projectId = await _firestoreService.createProject(project);

      final projectWithId = ProjectModel(
        id: projectId,
        ownerId: project.ownerId,
        projectName: project.projectName,
        description: project.description,
        developmentTrack: project.developmentTrack,
        languagesAndTools: project.languagesAndTools,
        projectSize: project.projectSize,
        dailyHours: project.dailyHours,
        createdAt: project.createdAt,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AiSearchResultsScreen(project: projectWithId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save project: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Project & Requirements'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Project Name *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your project name',
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter a project name' : null,
              ),
              const SizedBox(height: 16),
              const Text('Project Description *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describe goals, scope, and target collaborators',
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              const Text('Target Development Track', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedTrack,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['AI / Machine Learning', 'Mobile Development', 'Full Stack', 'Backend', 'Frontend']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTrack = val);
                },
              ),
              const SizedBox(height: 16),
              const Text('Required Languages & Tools (comma-separated)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _toolsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Python, PyTorch, FastApi, Flutter',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Project Size', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: ['Small', 'Medium', 'Large'].map((size) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(size),
                        selected: _selectedSize == size,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedSize = size);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Daily Hours Commitment', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: ['1-2 hrs', '3-5 hrs', '5+ hrs'].map((hours) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(hours),
                        selected: _dailyHours == hours,
                        onSelected: (selected) {
                          if (selected) setState(() => _dailyHours = hours);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox.shrink()
                      : const Icon(Icons.auto_awesome, color: Colors.white),
                  label: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Project & Find Collaborators',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                  onPressed: _isSubmitting ? null : _submitProject,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
