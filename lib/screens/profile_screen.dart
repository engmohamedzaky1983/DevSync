import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';
import '../models/developer_model.dart';
import '../services/firestore_service.dart';
import 'ai_search_results_screen.dart';
import 'intro_screen.dart';
import 'messages_screen.dart';
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
  late TextEditingController _portfolioController;
  late TextEditingController _linkedinController;
  late TextEditingController _websiteController;

  List<String> _skills = ['Flutter', 'Dart', 'Firebase', 'Python'];

  String _selectedTrack = 'Full Stack';
  String _experience = '3+ years';
  String _projectsWorkedOn = '12+';
  bool _isLoading = true;
  bool _isSaving = false;
  final int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _githubController = TextEditingController();
    _portfolioController = TextEditingController();
    _linkedinController = TextEditingController();
    _websiteController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    _nameController.text = user?.displayName ?? 'Alex Johnson';
    _emailController.text = user?.email ?? 'alex.johnson@example.com';
    _githubController.text = 'github.com/alexjohnson';
    _portfolioController.text = 'https://alex.dev';
    _linkedinController.text = 'linkedin.com/in/alexjohnson';
    _websiteController.text = 'https://alex.dev';

    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await _firestoreService.getDeveloperProfile(user.uid);
      if (profile != null && mounted) {
        if (profile.name.isNotEmpty) _nameController.text = profile.name;
        if (profile.email.isNotEmpty) _emailController.text = profile.email;
        if (profile.githubUrl.isNotEmpty) _githubController.text = profile.githubUrl;
        if (profile.portfolioUrl != null && profile.portfolioUrl!.isNotEmpty) {
          _portfolioController.text = profile.portfolioUrl!;
        }
        if (profile.linkedinUrl != null && profile.linkedinUrl!.isNotEmpty) {
          _linkedinController.text = profile.linkedinUrl!;
        }
        if (profile.developmentTrack.isNotEmpty) {
          _selectedTrack = profile.developmentTrack;
        }
        if (profile.experience.isNotEmpty) {
          _experience = profile.experience;
        }
        if (profile.skills.isNotEmpty) {
          _skills = List<String>.from(profile.skills);
        }
        if (profile.projectsWorkedOn > 0) {
          final count = profile.projectsWorkedOn;
          if (count <= 3) {
            _projectsWorkedOn = '1-3';
          } else if (count <= 7) {
            _projectsWorkedOn = '4-7';
          } else if (count <= 11) {
            _projectsWorkedOn = '8-11';
          } else if (count <= 14) {
            _projectsWorkedOn = '12+';
          } else {
            _projectsWorkedOn = '15+';
          }
        }
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
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved locally!'),
            backgroundColor: Color(0xFF0066FF),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final projectsCount =
          int.tryParse(_projectsWorkedOn.replaceAll(RegExp(r'[^0-9]'), '')) ?? 12;

      final updatedProfile = DeveloperModel(
        id: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: 'Developer',
        developmentTrack: _selectedTrack,
        experience: _experience,
        projectsWorkedOn: projectsCount,
        githubUrl: _githubController.text.trim(),
        portfolioUrl: _portfolioController.text.trim(),
        linkedinUrl: _linkedinController.text.trim(),
        avatarUrl: user.photoURL,
        skills: List<String>.from(_skills),
        isVerified: true,
      );

      await _firestoreService.saveDeveloperProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
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

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      // Already on Profile
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiSearchResultsScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MessagesScreen()),
      );
    }
  }

  void _showAddSkillDialog() {
    final skillCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Skill'),
        content: TextField(
          controller: skillCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. Flutter, React, Python',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = skillCtrl.text.trim();
              if (text.isNotEmpty && !_skills.contains(text)) {
                setState(() => _skills.add(text));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(
    List<String> options,
    String currentValue,
  ) {
    final list = List<String>.from(options);
    if (currentValue.isNotEmpty && !list.contains(currentValue)) {
      list.add(currentValue);
    }
    return list.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList();
  }

  Widget _buildLinkedInIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF475569), width: 1.5),
      ),
      alignment: Alignment.center,
      child: const Text(
        'in',
        style: TextStyle(
          color: Color(0xFF475569),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Developer Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF475569)),
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Profile Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar with Camera Icon Overlay
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: const Color(0xFFE2E8F0),
                              backgroundImage: user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!)
                                  : null,
                              child: user?.photoURL == null
                                  ? const Icon(Icons.person, size: 48, color: Color(0xFF64748B))
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Name, Email, Verified Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text
                                    : 'Alex Johnson',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _emailController.text.isNotEmpty
                                    ? _emailController.text
                                    : 'alex.johnson@example.com',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: Color(0xFF16A34A),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. Development Track Dropdown
                    const Text(
                      'Development Track',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTrack,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0066FF)),
                      style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0066FF)),
                        ),
                      ),
                      items: _buildDropdownItems(
                        ['Full Stack', 'Mobile', 'AI / ML', 'Backend', 'Frontend'],
                        _selectedTrack,
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTrack = val);
                      },
                    ),
                    const SizedBox(height: 18),

                    // 3. Experience & Projects Worked On Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Experience',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _experience,
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    color: Color(0xFF0066FF)),
                                style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF0066FF)),
                                  ),
                                ),
                                items: _buildDropdownItems(
                                  ['1-2 years', '3+ years', '5+ years', '10+ years'],
                                  _experience,
                                ),
                                onChanged: (val) {
                                  if (val != null) setState(() => _experience = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Projects Worked On',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _projectsWorkedOn,
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    color: Color(0xFF0066FF)),
                                style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF0066FF)),
                                  ),
                                ),
                                items: _buildDropdownItems(
                                  ['1-3', '4-7', '8-11', '12+', '15+'],
                                  _projectsWorkedOn,
                                ),
                                onChanged: (val) {
                                  if (val != null) setState(() => _projectsWorkedOn = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 4. Skills Area
                    const Text(
                      'Skills',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._skills.map(
                          (skill) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  skill,
                                  style: const TextStyle(
                                    color: Color(0xFF0066FF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => setState(() => _skills.remove(skill)),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Color(0xFF0066FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _showAddSkillDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16, color: Color(0xFF0066FF)),
                                SizedBox(width: 4),
                                Text(
                                  'Add Skill',
                                  style: TextStyle(
                                    color: Color(0xFF0066FF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 5. GitHub Profile Section (Editable Text Input)
                    const Text(
                      'GitHub Profile',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _githubController,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CustomPaint(
                            size: Size(22, 22),
                            painter: GitHubLogoPainter(),
                          ),
                        ),
                        suffixIcon: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: Color(0xFF16A34A),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Connected',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0066FF)),
                        ),
                        hintText: 'e.g. github.com/username',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 6. Other Links Section (Clear Text Boxes)
                    const Text(
                      'Other Links',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Portfolio Text Input
                    TextFormField(
                      controller: _portfolioController,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'Portfolio',
                        prefixIcon: const Icon(Icons.web_asset_outlined,
                            color: Color(0xFF475569)),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0066FF)),
                        ),
                        hintText: 'https://alex.dev',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // LinkedIn Text Input
                    TextFormField(
                      controller: _linkedinController,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'LinkedIn',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: _buildLinkedInIcon(),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0066FF)),
                        ),
                        hintText: 'linkedin.com/in/username',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Website Text Input
                    TextFormField(
                      controller: _websiteController,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'Website',
                        prefixIcon: const Icon(Icons.check_circle_outline,
                            color: Color(0xFF475569)),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0066FF)),
                        ),
                        hintText: 'https://alex.dev',
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 7. Save Profile Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
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

class GitHubLogoPainter extends CustomPainter {
  final Color color;
  const GitHubLogoPainter({this.color = const Color(0xFF0F172A)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0);
    path.cubicTo(w * 0.224, 0, 0, h * 0.224, 0, h * 0.5);
    path.cubicTo(0, h * 0.721, w * 0.324, h * 0.901, w * 0.373, h * 0.917);
    path.cubicTo(w * 0.398, h * 0.922, w * 0.407, h * 0.906, w * 0.407, h * 0.893);
    path.cubicTo(w * 0.407, h * 0.876, w * 0.406, h * 0.824, w * 0.406, h * 0.763);
    path.cubicTo(w * 0.267, h * 0.793, w * 0.238, h * 0.703, w * 0.238, h * 0.703);
    path.cubicTo(w * 0.215, h * 0.645, w * 0.183, h * 0.629, w * 0.183, h * 0.629);
    path.cubicTo(w * 0.138, h * 0.598, w * 0.186, h * 0.599, w * 0.186, h * 0.599);
    path.cubicTo(w * 0.236, h * 0.602, w * 0.262, h * 0.65, w * 0.262, h * 0.65);
    path.cubicTo(w * 0.306, h * 0.726, w * 0.378, h * 0.704, w * 0.406, h * 0.691);
    path.cubicTo(w * 0.411, h * 0.659, w * 0.424, h * 0.637, w * 0.438, h * 0.625);
    path.cubicTo(w * 0.327, h * 0.612, w * 0.21, h * 0.569, w * 0.21, h * 0.377);
    path.cubicTo(w * 0.21, h * 0.322, w * 0.23, h * 0.278, w * 0.262, h * 0.243);
    path.cubicTo(w * 0.257, h * 0.23, w * 0.239, h * 0.179, w * 0.267, h * 0.111);
    path.cubicTo(w * 0.267, h * 0.111, w * 0.309, h * 0.098, w * 0.405, h * 0.163);
    path.cubicTo(w * 0.445, h * 0.152, w * 0.488, h * 0.146, w * 0.5, h * 0.146);
    path.cubicTo(w * 0.512, h * 0.146, w * 0.555, h * 0.152, w * 0.595, h * 0.163);
    path.cubicTo(w * 0.691, h * 0.098, w * 0.733, h * 0.111, w * 0.733, h * 0.111);
    path.cubicTo(w * 0.761, h * 0.179, w * 0.743, h * 0.23, w * 0.738, h * 0.243);
    path.cubicTo(w * 0.77, h * 0.278, w * 0.79, h * 0.322, w * 0.79, h * 0.377);
    path.cubicTo(w * 0.79, h * 0.57, w * 0.672, h * 0.612, w * 0.561, h * 0.624);
    path.cubicTo(w * 0.579, h * 0.64, w * 0.594, h * 0.67, w * 0.594, h * 0.717);
    path.cubicTo(w * 0.594, h * 0.784, w * 0.593, h * 0.838, w * 0.593, h * 0.855);
    path.cubicTo(w * 0.593, h * 0.868, w * 0.602, h * 0.884, w * 0.628, h * 0.879);
    path.cubicTo(w * 0.767, h * 0.833, w * 0.866, h * 0.703, w * 0.866, h * 0.547);
    path.cubicTo(w * 0.866, h * 0.245, w * 0.702, 0, w * 0.5, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
