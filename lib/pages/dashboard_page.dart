import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'account_settings_page.dart';
import 'student_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardOverview(
        onStudentsTap: () => setState(() => _selectedIndex = 1),
        onAccountTap: () => setState(() => _selectedIndex = 2),
      ),
      const StudentsPage(),
      const AccountSettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DashboardOverview extends StatefulWidget {
  const _DashboardOverview({
    required this.onStudentsTap,
    required this.onAccountTap,
  });

  final VoidCallback onStudentsTap;
  final VoidCallback onAccountTap;

  @override
  State<_DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<_DashboardOverview> {
  static const _allYears = 'All Years';
  static const _allSemesters = 'All Semesters';
  String _selectedYearLevel = _allYears;
  String _selectedSemesterYear = _allSemesters;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final students = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students');
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user.displayName ?? user.email?.split('@').first ?? 'Student'}!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Welcome back to Student Information!',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: widget.onAccountTap,
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: students.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('Unable to load student count.'),
                    ),
                  );
                }
                final records = snapshot.data?.docs ?? [];
                final semesterOptions = [
                  _allSemesters,
                  ...records
                      .map((doc) => doc.data()['semesterYear'])
                      .whereType<String>()
                      .toSet()
                      .toList()
                    ..sort(),
                ];
                final selectedSemesterYear =
                    semesterOptions.contains(_selectedSemesterYear)
                    ? _selectedSemesterYear
                    : _allSemesters;
                final visibleRecords = records.where((doc) {
                  final data = doc.data();
                  return (_selectedYearLevel == _allYears ||
                          data['yearLevel'] == _selectedYearLevel) &&
                      (selectedSemesterYear == _allSemesters ||
                          data['semesterYear'] == selectedSemesterYear);
                }).toList();
                final activeCount = visibleRecords
                    .where(
                      (doc) => (doc.data()['status'] ?? 'Active') == 'Active',
                    )
                    .length;
                final droppedCount = visibleRecords
                    .where((doc) => doc.data()['status'] == 'Dropped')
                    .length;
                final totalCount = snapshot.hasData
                    ? '${visibleRecords.length}'
                    : '...';
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _OverviewFilter(
                            label: 'Year Level',
                            value: _selectedYearLevel,
                            options: const [
                              _allYears,
                              '1st Year',
                              '2nd Year',
                              '3rd Year',
                              '4th Year',
                            ],
                            onChanged: (value) => setState(
                              () => _selectedYearLevel = value ?? _allYears,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _OverviewFilter(
                            label: 'Semester / Year',
                            value: selectedSemesterYear,
                            options: semesterOptions,
                            onChanged: (value) => setState(
                              () => _selectedSemesterYear =
                                  value ?? _allSemesters,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F4E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            color: Color(0xFF087A3E),
                            size: 48,
                          ),
                          const SizedBox(width: 20),
                          Container(
                            width: 1,
                            height: 54,
                            color: Colors.black12,
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Students',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                totalCount,
                                style: const TextStyle(
                                  fontSize: 30,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF075C34),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _OverviewStatCard(
                            label: 'Active',
                            count: snapshot.hasData ? '$activeCount' : '...',
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF087A3E),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _OverviewStatCard(
                            label: 'Dropped',
                            count: snapshot.hasData ? '$droppedCount' : '...',
                            icon: Icons.cancel_outlined,
                            color: const Color(0xFFB3261E),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _OverviewStatCard(
                            label: 'Total',
                            count: totalCount,
                            icon: Icons.groups_outlined,
                            color: const Color(0xFF087A3E),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Access',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.school_rounded,
                    label: 'Student Records',
                    onTap: widget.onStudentsTap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.settings_rounded,
                    label: 'Account Settings',
                    onTap: widget.onAccountTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE7F5EC),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 116,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: const Color(0xFF087A3E)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewFilter extends StatelessWidget {
  const _OverviewFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  const _OverviewStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final String count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
