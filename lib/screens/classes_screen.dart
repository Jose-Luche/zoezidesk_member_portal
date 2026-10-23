// lib/screens/classes_screen.dart

import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<Map<String, dynamic>> _classes = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data    = await ApiClient.get('/member/classes');
      final classes = (data['classes'] as List)
          .cast<Map<String, dynamic>>();
      setState(() { _classes = classes; _loading = false; });
    } catch (e) {
      setState(() {
        _error   = 'Could not load classes.';
        _loading = false;
      });
    }
  }

  // Group classes by day
  Map<String, List<Map<String, dynamic>>> _groupByDay() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final c in _classes) {
      final day = c['day'] as String;
      grouped.putIfAbsent(day, () => []).add(c);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Class Timetable'),
        backgroundColor: AppTheme.background,
      ),
      body: RefreshIndicator(
        color: AppTheme.brand,
        onRefresh: _loadClasses,
        child: _loading
            ? const Center(child: CircularProgressIndicator(
            color: AppTheme.brand))
            : _error != null
            ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadClasses,
                  child: const Text('Retry'),
                ),
              ],
            ))
            : _classes.isEmpty
            ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 48, color: AppTheme.textFaint),
                SizedBox(height: 12),
                Text('No classes this week',
                    style: TextStyle(color: AppTheme.textFaint)),
              ],
            ))
            : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    final grouped = _groupByDay();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(entry.key,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5)),
            ),

            // Class cards for this day
            ...entry.value.map((c) => _ClassCard(classData: c)),

            const SizedBox(height: 4),
          ],
        );
      }).toList(),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  const _ClassCard({required this.classData});

  @override
  Widget build(BuildContext context) {
    final color     = _hexToColor(classData['color'] as String? ?? '#534AB7');
    final className = classData['class_name'] as String;
    final startTime = classData['start_time'] as String;
    final endTime   = classData['end_time']   as String;
    final instructor= classData['instructor'] as String?;
    final spotsLeft = classData['spots_left'] as int;
    final isFull    = classData['is_full']    as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Color stripe
            Container(
              width: 4, height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 14),

            // Class info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(className,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: AppTheme.textFaint),
                      const SizedBox(width: 4),
                      Text('$startTime – $endTime',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textFaint)),
                      if (instructor != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.person_outline,
                            size: 12, color: AppTheme.textFaint),
                        const SizedBox(width: 4),
                        Text(instructor,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textFaint)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Capacity badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isFull
                    ? AppTheme.danger.withOpacity(0.1)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                  isFull ? 'Full' : '$spotsLeft left',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: isFull ? AppTheme.danger : color)),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}