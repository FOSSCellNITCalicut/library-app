import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:library_nitc/curriculum_provider.dart';

class ProgrammeSelectionPage extends StatefulWidget {
  const ProgrammeSelectionPage({super.key});

  @override
  State<ProgrammeSelectionPage> createState() => _ProgrammeSelectionPageState();
}

class _ProgrammeSelectionPageState extends State<ProgrammeSelectionPage> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<CurriculumProvider>();
    if (!provider.isLoaded) {
      provider.loadCurriculum();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Curriculum'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: Consumer<CurriculumProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !provider.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && !provider.isLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadCurriculum(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!provider.isLoaded) {
            return const Center(child: Text('No curriculum data available'));
          }

          final programmes = provider.data!['programmes'] as Map<String, dynamic>;
          final entries = programmes.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final key = entry.key;
              final prog = entry.value as Map<String, dynamic>;
              final name = prog['name'] as String? ?? key;
              final branches = prog['branches'] as Map<String, dynamic>? ?? {};

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                    child: const Icon(Icons.school, color: Color(0xFF6A1B9A)),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('${branches.length} branches'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BranchSelectionPage(
                          programmeKey: key,
                          programmeName: name,
                          branches: branches,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BranchSelectionPage extends StatelessWidget {
  final String programmeKey;
  final String programmeName;
  final Map<String, dynamic> branches;

  const BranchSelectionPage({
    required this.programmeKey,
    required this.programmeName,
    required this.branches,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final entries = branches.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(programmeName),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: entries.isEmpty
          ? const Center(child: Text('No branches available'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final key = entry.key;
                final branch = entry.value as Map<String, dynamic>;
                final name = branch['name'] as String? ?? key;
                final courses = branch['courses'] as Map<String, dynamic>? ?? {};

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                      child: const Icon(Icons.account_balance, color: Color(0xFF6A1B9A)),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('${courses.length} courses'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CourseSelectionPage(
                            branchName: name,
                            courses: courses,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class CourseSelectionPage extends StatelessWidget {
  final String branchName;
  final Map<String, dynamic> courses;

  const CourseSelectionPage({
    required this.branchName,
    required this.courses,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final entries = courses.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(branchName),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: entries.isEmpty
          ? const Center(child: Text('No courses available'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final courseId = entry.key;
                final courseName = entry.value as String;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                      child: const Icon(Icons.book_outlined, color: Color(0xFF6A1B9A)),
                    ),
                    title: Text(
                      courseName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(courseId, style: const TextStyle(fontSize: 13)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        courseId,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6A1B9A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Books for $courseName coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
