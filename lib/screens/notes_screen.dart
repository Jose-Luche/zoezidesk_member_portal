// lib/screens/notes_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes  = [];
  bool    _loading                   = true;
  bool    _saving                    = false;
  String? _error;
  String  _filterType                = 'all';

  // Add note form
  final _noteController = TextEditingController();
  String _selectedType  = 'general';
  String _selectedDate  = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data  = await ApiClient.get('/member/notes');
      final notes = (data['notes'] as List).cast<Map<String, dynamic>>();
      setState(() { _notes = notes; _loading = false; });
    } catch (e) {
      setState(() {
        _error   = 'Could not load notes.';
        _loading = false;
      });
    }
  }

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);

    try {
      final data = await ApiClient.post('/member/notes', {
        'type'     : _selectedType,
        'note'     : text,
        'log_date' : _selectedDate,
      });

      if (data['success'] == true) {
        // Add new note to top of list
        setState(() {
          _notes.insert(0, data['note'] as Map<String, dynamic>);
          _noteController.clear();
          _selectedType = 'general';
          _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        });

        // Dismiss keyboard
        if (mounted) FocusScope.of(context).unfocus();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save note. Try again.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateNote(
      int id,
      String type,
      String note,
      String logDate,
      ) async {
    await ApiClient.put('/member/notes/$id', {
      'type': type,
      'note': note,
      'log_date': logDate,
    });

    await _loadNotes();
  }

  Future<void> _deleteNote(int id, int index) async {
    // Optimistic removal — remove from UI immediately
    final removed = _notes[index];
    setState(() => _notes.removeAt(index));

    try {
      await ApiClient.delete('/member/notes/$id');
    } catch (e) {
      // Restore if delete failed
      setState(() => _notes.insert(index, removed));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete note.')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredNotes {
    if (_filterType == 'all') return _notes;
    return _notes.where((n) => n['type'] == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Journal'),
        backgroundColor: AppTheme.background,
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.brand))
          : Column(
        children: [
          // Add note card — always visible at top
          _buildAddNoteCard(),
          // Filter pills
          _buildFilterPills(),
          // Notes list
          Expanded(child: _buildNotesList()),
        ],
      ),
    );
  }

  // ── Add note card ─────────────────────────────────────────────────
  Widget _buildAddNoteCard() {
    return Container(
      color: AppTheme.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Type selector row
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _noteTypes.map((t) {
                final isSelected = _selectedType == t['value'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedType = t['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.brand
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.brand
                            : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t['icon']!,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          t['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppTheme.onBrand
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Date picker row
          GestureDetector(
            onTap: _pickDate,
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppTheme.textFaint),
                const SizedBox(width: 6),
                Text(
                  DateFormat('d MMM yyyy').format(
                      DateFormat('yyyy-MM-dd').parse(_selectedDate)),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textFaint,
                    decoration: TextDecoration.underline,
                    decorationColor: AppTheme.textFaint,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit_outlined,
                    size: 12, color: AppTheme.textFaint),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Text input + save button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText:
                    'What did you do today? How are you feeling?',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textFaint,
                    ),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppTheme.brand, width: 2),
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Save button
              GestureDetector(
                onTap: _saving ? null : _saveNote,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _saving
                        ? AppTheme.brand.withValues(alpha: 0.5)
                        : AppTheme.brand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _saving
                      ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: AppTheme.onBrand,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.send_rounded,
                      color: AppTheme.onBrand, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Filter pills ──────────────────────────────────────────────────
  Widget _buildFilterPills() {
    final allTypes = [
      {'value': 'all',       'icon': '📋', 'label': 'All'},
      ..._noteTypes,
    ];

    return Container(
      color: AppTheme.card,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: allTypes.map((t) {
                final isSelected = _filterType == t['value'];
                // Count notes of this type
                final count = t['value'] == 'all'
                    ? _notes.length
                    : _notes
                    .where((n) => n['type'] == t['value'])
                    .length;

                if (count == 0 && t['value'] != 'all') {
                  return const SizedBox.shrink();
                }

                return GestureDetector(
                  onTap: () =>
                      setState(() => _filterType = t['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.brand
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.brand
                            : AppTheme.border,
                      ),
                    ),
                    child: Text(
                      '${t['icon']} ${t['label']} $count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppTheme.onBrand
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notes list ────────────────────────────────────────────────────
  Widget _buildNotesList() {
    final filtered = _filteredNotes;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _filterType == 'all' ? '📓' : _noteTypes
                  .firstWhere((t) => t['value'] == _filterType,
                  orElse: () => {'icon': '📋'})['icon']!,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              _filterType == 'all'
                  ? 'Your journal is empty'
                  : 'No ${_filterType} entries yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first entry above',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textFaint,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.brand,
      onRefresh: _loadNotes,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final note = filtered[index];
          // Find the actual index in _notes for deletion
          final actualIndex = _notes.indexOf(note);
          return _NoteCard(
            note:    note,
            onDelete: () => _deleteNote(note['id'] as int, actualIndex),
            onEdit:   () => _showEditDialog(note),
          );
        },
      ),
    );
  }

  // ── Date picker ───────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: DateTime.now(),
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.brand,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> note) async {
    final controller = TextEditingController(text: note['note'] as String);
    String selectedType = note['type'] as String;
    String selectedDate = note['log_date'] as String;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Edit entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: _noteTypes
                    .map((t) => DropdownMenuItem(
                  value: t['value'],
                  child: Text('${t['icon']} ${t['label']}'),
                ))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Save', style: TextStyle(color: AppTheme.brand)),
            ),
          ],
        ),
      ),
    );

    if (saved == true && controller.text.trim().isNotEmpty) {
      await _updateNote(
        note['id'] as int,
        selectedType,
        controller.text.trim(),
        selectedDate,
      );
    }
    controller.dispose();
  }
}

// ── Note types config ─────────────────────────────────────────────────
const _noteTypes = [
  {'value': 'workout',   'icon': '💪', 'label': 'Workout'},
  {'value': 'progress',  'icon': '📈', 'label': 'Progress'},
  {'value': 'goal',      'icon': '🎯', 'label': 'Goal'},
  {'value': 'nutrition', 'icon': '🥗', 'label': 'Nutrition'},
  {'value': 'general',   'icon': '📝', 'label': 'Note'},
];

// ── Note card widget ──────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _NoteCard({
    required this.note,
    required this.onDelete,
    required this.onEdit,
  });

  Color _typeColor(String type) {
    return switch (type) {
      'workout'   => AppTheme.brand,
      'progress'  => AppTheme.success,
      'goal'      => AppTheme.warning,
      'nutrition' => AppTheme.success,
      _           => const Color(0xFF6B7280),
    };
  }

  String _typeIcon(String type) {
    return switch (type) {
      'workout'   => '💪',
      'progress'  => '📈',
      'goal'      => '🎯',
      'nutrition' => '🥗',
      _           => '📝',
    };
  }

  String _typeLabel(String type) {
    return switch (type) {
      'workout'   => 'Workout',
      'progress'  => 'Progress',
      'goal'      => 'Goal',
      'nutrition' => 'Nutrition',
      _           => 'Note',
    };
  }

  @override
  Widget build(BuildContext context) {
    final type     = note['type'] as String;
    final color    = _typeColor(type);
    final updated  = note['updated'] as bool? ?? false;

    return Dismissible(
      // Swipe left to delete
      key: Key('note_${note['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            title: const Text('Delete entry?'),
            content: const Text(
                'This entry will be permanently removed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: TextStyle(color: AppTheme.danger)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 22),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: IntrinsicHeight(
          child: Row(
            children: [

              // Color stripe — mirrors the web version
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft:    Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Type badge + date row
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: onEdit,
                          ),
                          Text(_typeIcon(type),
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              _typeLabel(type),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            note['log_date'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textFaint,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Note text
                      Text(
                        note['note'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Relative time + edited badge
                      Row(
                        children: [
                          Text(
                            note['created_at'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textFaint,
                            ),
                          ),
                          if (updated) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· edited',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textFaint,
                              ),
                            ),
                          ],
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}