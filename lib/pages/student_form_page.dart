import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../data/student_repository.dart';

class StudentFormPage extends StatefulWidget {
  const StudentFormPage({super.key, this.documentId, this.initialData});

  final String? documentId;
  final Map<String, dynamic>? initialData;

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  static const _yearLevels = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  static const _statuses = ['Active', 'Dropped'];

  final _key = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _name = TextEditingController();
  late final List<String> _semesterYears;
  String? _yearLevel;
  late String _semesterYear;
  String _status = 'Active';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _number.text = data['studentNumber'] ?? '';
    _name.text = data['fullName'] ?? '';
    _yearLevel = _yearLevels.contains(data['yearLevel'])
        ? data['yearLevel'] as String
        : null;
    final currentYear = DateTime.now().year;
    _semesterYears = [
      for (
        var startYear = currentYear - 1;
        startYear <= currentYear + 1;
        startYear++
      )
        for (final semester in ['1st Semester', '2nd Semester', 'Summer'])
          '$semester $startYear-${startYear + 1}',
    ];
    final savedSemesterYear = data['semesterYear'];
    final defaultSemesterYear = '1st Semester $currentYear-${currentYear + 1}';
    _semesterYear = _semesterYears.contains(savedSemesterYear)
        ? savedSemesterYear as String
        : defaultSemesterYear;
    final savedStatus = data['status'];
    _status = _statuses.contains(savedStatus)
        ? savedStatus as String
        : 'Active';
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to save students.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await StudentRepository(user.uid).saveStudent(
        documentId: widget.documentId,
        data: {
          'studentNumber': _number.text.trim(),
          'fullName': _name.text.trim(),
          'yearLevel': _yearLevel,
          'semesterYear': _semesterYear,
          'status': _status,
        },
      );
      if (!mounted) return;
      final isAdding = widget.documentId == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isAdding ? const Color(0xFF087A3E) : null,
          content: Text(
            isAdding
                ? 'Student added successfully.'
                : 'Student updated successfully.',
            style: isAdding ? const TextStyle(color: Colors.white) : null,
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label ',
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? '$label is required' : null,
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: '$label ',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Select $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.documentId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Student' : 'Add Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFE7F0F3),
                  child: Icon(Icons.person, size: 48, color: Color(0xFF536872)),
                ),
              ),
              const SizedBox(height: 20),
              _textField(_name, 'Full Name', icon: Icons.person_outline),
              _textField(_number, 'Student ID', icon: Icons.badge_outlined),
              _dropdown(
                label: 'Year Level',
                value: _yearLevel,
                options: _yearLevels,
                onChanged: (value) => setState(() => _yearLevel = value),
              ),
              _dropdown(
                label: 'Semester / Year',
                value: _semesterYear,
                options: _semesterYears,
                onChanged: (value) {
                  if (value != null) setState(() => _semesterYear = value);
                },
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Status ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Active',
                    icon: Icon(Icons.check_circle_outline),
                    label: Text('Active'),
                  ),
                  ButtonSegment(
                    value: 'Dropped',
                    icon: Icon(Icons.cancel_outlined),
                    label: Text('Dropped'),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: _saving
                    ? null
                    : (selection) => setState(() => _status = selection.first),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save Student'),
              ),
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
