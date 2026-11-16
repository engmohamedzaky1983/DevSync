import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_model.dart';
import '../services/firestore_service.dart';
import 'ai_search_results_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  String _selectedTrack = 'AI/machine learning';

  final List<String> _languagesAndTools = ['Python', 'TypeScript', 'JavaScript'];
  final List<String> _frameworksAndPlatforms = ['FastAPI', 'Docker', 'GitHub'];

  String _projectSize = 'Small';
  String _dailyHours = '3-5';
  String _projectDuration = 'Weeks';
  int _requiredDevelopers = 2;
  String _experienceLevel = 'Mid-level';
  String _availability = 'Part-time';

  final Set<String> _confirmedAccounts = {'GitHub', 'GitLab', 'LinkedIn', 'Portfolio'};

  bool _isSubmitting = false;
  final int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest_user';

    setState(() => _isSubmitting = true);

    try {
      final project = ProjectModel(
        id: '',
        ownerId: userId,
        projectName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        developmentTrack: _selectedTrack,
        languagesAndTools: List.from(_languagesAndTools),
        frameworksAndPlatforms: List.from(_frameworksAndPlatforms),
        projectSize: _projectSize,
        dailyHours: _dailyHours,
        projectDuration: _projectDuration,
        requiredDevelopers: _requiredDevelopers,
        experienceLevel: _experienceLevel,
        availability: _availability,
        createdAt: DateTime.now(),
      );

      String generatedId = '';
      if (user != null) {
        generatedId = await _firestoreService.createProject(project);
      }

      final projectWithId = ProjectModel(
        id: generatedId.isNotEmpty ? generatedId : 'demo_project',
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
          SnackBar(
            content: Text('Failed to save project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else if (index == 1) {
      // Already on Projects Screen
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

  void _showAddSkillDialog(String category, List<String> targetList) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add $category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Flutter, GraphQL, AWS',
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
              final val = controller.text.trim();
              if (val.isNotEmpty && !targetList.contains(val)) {
                setState(() => targetList.add(val));
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          children: isRequired
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildPillOption(
    String label,
    String currentValue,
    Function(String) onSelect,
  ) {
    final isSelected = currentValue == label;
    return InkWell(
      onTap: () => onSelect(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0066FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillTag(String tag, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: Color(0xFF0066FF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFF0066FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSkillButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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
              'Add',
              style: TextStyle(
                color: Color(0xFF0066FF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountChip({
    required Widget icon,
    required String label,
  }) {
    final isSelected = _confirmedAccounts.contains(label);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _confirmedAccounts.remove(label);
          } else {
            _confirmedAccounts.add(label);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 18, height: 18, child: Center(child: icon)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedInIcon() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF475569), width: 1.2),
      ),
      alignment: Alignment.center,
      child: const Text(
        'in',
        style: TextStyle(
          color: Color(0xFF475569),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'New Project & Skills',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Project Details
              _buildSectionHeader('Project Details'),
              _buildFieldLabel('Project Name', isRequired: true),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'e.g. AI Code Review Assistant',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0066FF)),
                  ),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter a project name' : null,
              ),
              const SizedBox(height: 16),
              _buildFieldLabel('Description', isRequired: true),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Describe goals, scope, and target collaborators',
                  contentPadding: const EdgeInsets.all(16),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0066FF)),
                  ),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              _buildFieldLabel('Development Track', isRequired: true),
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
                  [
                    'AI/machine learning',
                    'mobile APP',
                    'Web',
                    'frontend',
                    'backend',
                    'fullstack',
                  ],
                  _selectedTrack,
                ),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTrack = val);
                },
              ),
              const SizedBox(height: 24),

              // 2. Required Skills
              _buildSectionHeader('Required Skills'),
              const Text(
                'Languages & Tools',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._languagesAndTools.map(
                    (item) => _buildSkillTag(
                      item,
                      () => setState(() => _languagesAndTools.remove(item)),
                    ),
                  ),
                  _buildAddSkillButton(
                    () => _showAddSkillDialog('Language or Tool', _languagesAndTools),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Frameworks & Platforms',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._frameworksAndPlatforms.map(
                    (item) => _buildSkillTag(
                      item,
                      () => setState(() => _frameworksAndPlatforms.remove(item)),
                    ),
                  ),
                  _buildAddSkillButton(
                    () => _showAddSkillDialog('Framework or Platform', _frameworksAndPlatforms),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Team & Timeline
              _buildSectionHeader('Team & Timeline'),
              const Text(
                'Project Size',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Small', 'Medium', 'Large'].map((size) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: _buildPillOption(
                        size,
                        _projectSize,
                        (val) => setState(() => _projectSize = val),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Daily Hours',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['1-2', '3-5', '6-8', 'Flexible'].map((hours) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: _buildPillOption(
                        hours,
                        _dailyHours,
                        (val) => setState(() => _dailyHours = val),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Project Duration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Weeks', 'Months'].map((duration) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: _buildPillOption(
                        duration,
                        _projectDuration,
                        (val) => setState(() => _projectDuration = val),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Required Developers',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: _requiredDevelopers,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0066FF)),
                          style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            prefixIcon: const Icon(Icons.people_outline,
                                color: Color(0xFF475569), size: 20),
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
                          items: ([1, 2, 3, 4, 5].contains(_requiredDevelopers)
                                  ? [1, 2, 3, 4, 5]
                                  : [...[1, 2, 3, 4, 5], _requiredDevelopers])
                              .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _requiredDevelopers = val);
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
                          'Experience Level',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _experienceLevel,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0066FF)),
                          style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            ['Junior', 'Mid-level', 'Senior', 'Lead'],
                            _experienceLevel,
                          ),
                          onChanged: (val) {
                            if (val != null) setState(() => _experienceLevel = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Availability',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Part-time', 'Full-time', 'Flexible'].map((avail) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: _buildPillOption(
                        avail,
                        _availability,
                        (val) => setState(() => _availability = val),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirmed Accounts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAccountChip(
                    icon: const CustomPaint(
                      size: Size(18, 18),
                      painter: GitHubLogoPainter(),
                    ),
                    label: 'GitHub',
                  ),
                  _buildAccountChip(
                    icon: const Icon(Icons.local_fire_department,
                        color: Color(0xFFF97316), size: 18),
                    label: 'GitLab',
                  ),
                  _buildAccountChip(
                    icon: _buildLinkedInIcon(),
                    label: 'LinkedIn',
                  ),
                  _buildAccountChip(
                    icon: const Icon(Icons.crop_square_outlined,
                        color: Color(0xFF475569), size: 18),
                    label: 'Portfolio',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 4. CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox.shrink()
                      : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  label: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Find Collaborators with AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  onPressed: _isSubmitting ? null : _submitProject,
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
