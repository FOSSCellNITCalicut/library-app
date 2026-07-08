import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:library_nitc/catalogBooksPage.dart';
import 'package:library_nitc/curriculum_provider.dart';
import 'package:library_nitc/theme/app_colors.dart';

String _iconCode(Map<String, dynamic> courses) {
  final codes = courses.keys.map((id) => RegExp(r'^[A-Z]+').stringMatch(id) ?? '').toList();
  final freq = <String, int>{};
  var best = '';
  var bestCount = 0;
  for (final c in codes) {
    if (c.isEmpty) continue;
    freq[c] = (freq[c] ?? 0) + 1;
    if (freq[c]! > bestCount) {
      bestCount = freq[c]!;
      best = c;
    }
  }
  return best;
}

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
        backgroundColor: context.cs.primary,
        foregroundColor: context.cs.surface,
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

          final programmes = provider.data!['Programmes'] as Map<String, dynamic>;
          final entries = programmes.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final programmeName = entry.key;
              final branches = entry.value as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: context.cs.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.school, color: context.cs.primary),
                  ),
                  title: Text(
                    programmeName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('${branches.length} branches'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BranchSelectionPage(
                          programmeName: programmeName,
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
  final String programmeName;
  final Map<String, dynamic> branches;

  const BranchSelectionPage({
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
        backgroundColor: context.cs.primary,
        foregroundColor: context.cs.surface,
      ),
      body: entries.isEmpty
          ? const Center(child: Text('No branches available'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final branchName = entry.key;
                final courses = entry.value as Map<String, dynamic>;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: context.cs.primary.withValues(alpha: 0.1),
                      backgroundImage: AssetImage('assets/icons/${_iconCode(courses)}.png'),
                      child: courses.keys.isEmpty
                          ? Icon(Icons.account_balance, color: context.cs.primary)
                          : null,
                    ),
                    title: Text(
                      branchName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('${courses.length} courses'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CourseSelectionPage(
                            branchName: branchName,
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
        backgroundColor: context.cs.primary,
        foregroundColor: context.cs.surface,
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
                      backgroundColor: context.cs.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.book_outlined, color: context.cs.primary),
                    ),
                    title: Text(
                      courseName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(courseId, style: const TextStyle(fontSize: 13)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        courseId,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CatalogBooksPage(
                            courseId: courseId,
                            courseName: courseName,
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
