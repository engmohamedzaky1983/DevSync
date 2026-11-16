import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';
import '../models/developer_model.dart';
import '../services/firestore_service.dart';
import 'intro_screen.dart';
import 'project_form_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _githubController;
  late TextEditingController _skillsController;

  String _selectedTrack = 'Full Stack';
  String _experience = '1-2 years';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _githubController = TextEditingController();
    _skillsController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _githubController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _nameController.text = user.displayName ?? '';
    _emailController.text = user.email ?? '';

    try {
      final profile = await _firestoreService.getDeveloperProfile(user.uid);
      if (profile != null && mounted) {
        if (profile.name.isNotEmpty) _nameController.text = profile.name;
        if (profile.email.isNotEmpty) _emailController.text = profile.email;
        _githubController.text = profile.githubUrl;
        _selectedTrack = profile.developmentTrack;
        _experience = profile.experience;
        _skillsController.text = profile.skills.join(', ');
      }
    } catch (e) {
      debugPrint("Error loading profile from Firestore: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final skills = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final updatedProfile = DeveloperModel(
        id: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: 'Developer',
        developmentTrack: _selectedTrack,
        experience: _experience,
        githubUrl: _githubController.text.trim(),
        avatarUrl: user.photoURL,
        skills: skills,
      );

      await _firestoreService.saveDeveloperProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await context.read<AuthCubit>().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const IntroScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF0066FF).withValues(alpha: 0.1),
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? const Icon(Icons.person, size: 48, color: Color(0xFF0066FF))
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : 'Developer',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _emailController.text,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Development Track', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTrack,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ['Full Stack', 'Mobile', 'AI / ML', 'Backend', 'Frontend']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTrack = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Experience Level', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _experience,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ['Junior (< 1 yr)', '1-2 years', '3+ years', '5+ years']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _experience = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('GitHub Username or URL *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _githubController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.code),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. github.com/username',
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Please enter your GitHub profile' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Skills (comma-separated)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.star_outline),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Flutter, Dart, Firebase, Python',
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save & Next: New Project',
                                style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
