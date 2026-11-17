import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../data/student_repository.dart';
import 'student_form_page.dart';

class StudentDetailsPage extends StatelessWidget {
  const StudentDetailsPage({required this.documentId, super.key});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final repository = StudentRepository(user.uid);
    return StreamBuilder(
      stream: repository.watchStudent(documentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Unable to load student details.')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Student Details')),
            body: const Center(child: Text('This student record was deleted.')),
          );
        }

        final data = snapshot.data!.data()!;
        final status = data['status'] ?? 'Active';
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Student Details'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'edit') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentFormPage(
                            documentId: documentId,
                            initialData: data,
                          ),
                        ),
                      );
                    } else if (action == 'delete') {
                      await _delete(context, repository, data);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFFE7F0F3),
                        child: const Icon(
                          Icons.person,
                          size: 38,
                          color: Color(0xFF536872),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['fullName'] ?? ''}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${data['studentNumber'] ?? ''}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(status: '$status'),
                    ],
                  ),
                ),
                TabBar(
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Activity'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _DetailsTab(
                        data: data,
                        onChangeStatus: () =>
                            _changeStatus(context, repository, data),
                      ),
                      _ActivityTab(
                        stream: repository.watchActivity(documentId),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentFormPage(
                            documentId: documentId,
                            initialData: data,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _delete(context, repository, data),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB3261E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    StudentRepository repository,
    Map<String, dynamic> data,
  ) async {
    var selectedStatus = (data['status'] ?? 'Active') as String;
    final updatedStatus = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Select the new status for this student.'),
              ),
              const SizedBox(height: 12),
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
                selected: {selectedStatus},
                onSelectionChanged: (selection) =>
                    setDialogState(() => selectedStatus = selection.first),
              ),
              const SizedBox(height: 8),
              Text(
                selectedStatus == 'Active'
                    ? 'Student is currently enrolled.'
                    : 'Student is no longer enrolled.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selectedStatus),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
    if (updatedStatus == null || updatedStatus == data['status']) return;
    try {
      await repository.updateStatus(
        documentId: documentId,
        studentName: '${data['fullName'] ?? ''}',
        status: updatedStatus,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student status updated.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status update failed: $error')));
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    StudentRepository repository,
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
      Navigator.pop(context, true);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
      }
    }
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.data, required this.onChangeStatus});

  final Map<String, dynamic> data;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Active';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          child: Column(
            children: [
              _DetailRow(
                label: 'Year Level',
                value: '${data['yearLevel'] ?? 'Not set'}',
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _DetailRow(
                label: 'Semester / Year',
                value: '${data['semesterYear'] ?? 'Not set'}',
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _DetailRow(label: 'Status', value: '$status'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onChangeStatus,
          icon: const Icon(Icons.sync_alt),
          label: const Text('Change Status'),
        ),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.stream});

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load student activity.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = [...snapshot.data!.docs]
          ..sort((a, b) {
            final aTime = a.data()['createdAt'];
            final bTime = b.data()['createdAt'];
            if (aTime is! Timestamp || bTime is! Timestamp) return 0;
            return bTime.compareTo(aTime);
          });
        if (events.isEmpty) {
          return const Center(child: Text('No activity yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final data = events[index].data();
            final action = '${data['action'] ?? 'updated'}';
            final message = switch (action) {
              'created' => 'Student record added',
              'updated' => 'Student record updated',
              'status_changed' => 'Status changed to ${data['status']}',
              'deleted' => 'Student record deleted',
              _ => 'Student record updated',
            };
            final timestamp = data['createdAt'];
            final time = timestamp is Timestamp
                ? _formatTime(timestamp.toDate())
                : 'Just now';
            return Card(
              color: Colors.white,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDDF2E5),
                  child: Icon(Icons.history, color: Color(0xFF087A3E)),
                ),
                title: Text(message),
                subtitle: Text(time),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.month}/${local.day}/${local.year} • $hour:$minute $period';
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );
  }
}
