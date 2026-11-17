import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../data/student_repository.dart';
import 'student_details_page.dart';
import 'student_form_page.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final repository = StudentRepository(user.uid);
    return Scaffold(
      appBar: AppBar(title: const Text('Student Records')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentFormPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search student...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: repository.watchStudents(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Unable to load students from Firebase.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final query = _searchController.text.trim().toLowerCase();
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final matchesQuery = [
                    data['fullName'],
                    data['studentNumber'],
                    data['yearLevel'],
                    data['semesterYear'],
                  ].any((value) => '$value'.toLowerCase().contains(query));
                  final status = data['status'] ?? 'Active';
                  return matchesQuery &&
                      (_statusFilter == 'All' || status == _statusFilter);
                }).toList();
                final emptyMessage = query.isNotEmpty
                    ? 'No students found.'
                    : _statusFilter == 'All'
                    ? 'No student records yet.\nTap Add Student to begin.'
                    : 'No $_statusFilter students found.';

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'All', label: Text('All')),
                          ButtonSegment(value: 'Active', label: Text('Active')),
                          ButtonSegment(
                            value: 'Dropped',
                            label: Text('Dropped'),
                          ),
                        ],
                        selected: {_statusFilter},
                        onSelectionChanged: (selection) =>
                            setState(() => _statusFilter = selection.first),
                      ),
                    ),
                    Expanded(
                      child: docs.isEmpty
                          ? Center(
                              child: Text(
                                emptyMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data();
                                final status = '${data['status'] ?? 'Active'}';
                                return Card(
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(bottom: 9),
                                  child: ListTile(
                                    onTap: () => _openDetails(context, doc.id),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFE7F0F3),
                                      child: const Icon(
                                        Icons.person,
                                        color: Color(0xFF536872),
                                      ),
                                    ),
                                    title: Text(
                                      '${data['fullName'] ?? ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${data['studentNumber'] ?? ''}\n${data['yearLevel'] ?? ''} • ${data['semesterYear'] ?? ''}',
                                    ),
                                    isThreeLine: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _StatusChip(status: status),
                                        PopupMenuButton<String>(
                                          onSelected: (action) {
                                            if (action == 'edit') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      StudentFormPage(
                                                        documentId: doc.id,
                                                        initialData: data,
                                                      ),
                                                ),
                                              );
                                            } else if (action == 'delete') {
                                              _confirmDelete(
                                                context,
                                                repository,
                                                doc.id,
                                                data,
                                              );
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit'),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, String documentId) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentDetailsPage(documentId: documentId),
      ),
    );
    if (deleted != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFFB3261E),
        content: Text(
          'Student deleted successfully.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StudentRepository repository,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('Delete ${data['fullName']}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await repository.deleteStudent(documentId: documentId, data: data);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFB3261E),
          content: Text(
            'Student deleted successfully.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final dropped = status == 'Dropped';
    return Chip(
      label: Text(status),
      backgroundColor: dropped
          ? const Color(0xFFFCE8E6)
          : const Color(0xFFDDF2E5),
      labelStyle: TextStyle(
        color: dropped ? const Color(0xFFB3261E) : const Color(0xFF087A3E),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
    );
  }
}
