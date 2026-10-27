import 'dart:math';
import 'package:flutter/material.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  static final List<Map<String, dynamic>> _flashcards = [];
  static final List<Map<String, dynamic>> _recentlyDeleted = [];
  static final List<String> _subjects = ['General'];

  final Set<String> _reviewedCardIds = {};
  final TextEditingController _searchController = TextEditingController();

  String _selectedSubject = 'All';
  DateTimeRange? _selectedDateRange;
  bool _isShuffle = false;
  int _correct = 0;
  int _wrong = 0;
  Map<String, dynamic>? _lastDeletedCard;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _cardSubject(Map<String, dynamic> card) {
    final subject = (card['subject'] ?? 'General').toString().trim();
    return subject.isEmpty ? 'General' : subject;
  }

  DateTime? _cardCreatedAt(Map<String, dynamic> card) {
    final value = card['createdAt'];
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown date';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  bool _isSameFlashcard(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    final firstId = (first['id'] ?? '').toString();
    final secondId = (second['id'] ?? '').toString();
    if (firstId.isNotEmpty && secondId.isNotEmpty && firstId == secondId) {
      return true;
    }

    return (first['front'] ?? '').toString() ==
            (second['front'] ?? '').toString() &&
        (first['back'] ?? '').toString() == (second['back'] ?? '').toString() &&
        _cardSubject(first).toLowerCase() == _cardSubject(second).toLowerCase();
  }

  List<Map<String, dynamic>> get _filteredFlashcards {
    final query = _searchController.text.trim().toLowerCase();

    return _flashcards.where((card) {
      final subject = _cardSubject(card).toLowerCase();
      final front = (card['front'] ?? '').toString().toLowerCase();
      final back = (card['back'] ?? '').toString().toLowerCase();
      final createdAt = _cardCreatedAt(card);

      final matchesQuery =
          query.isEmpty ||
          front.contains(query) ||
          back.contains(query) ||
          subject.contains(query) ||
          (card['id'] ?? '').toString().toLowerCase().contains(query);

      final matchesSubject =
          _selectedSubject == 'All' ||
          subject == _selectedSubject.toLowerCase();

      bool matchesDate = true;
      if (_selectedDateRange != null && createdAt != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
        );
        final candidate = DateTime(
          createdAt.year,
          createdAt.month,
          createdAt.day,
        );
        matchesDate = !candidate.isBefore(start) && !candidate.isAfter(end);
      }

      return matchesQuery && matchesSubject && matchesDate;
    }).toList();
  }

  Map<String, dynamic> _buildFlashcard({
    required String front,
    required String back,
    String subject = 'General',
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return {
      'id':
          'flashcard_${now.microsecondsSinceEpoch}_${Random().nextInt(100000)}',
      'front': front,
      'back': back,
      'subject': subject,
      'createdAt': now.toUtc().toIso8601String(),
    };
  }

  void _addSubjectIfNeeded(String subject) {
    final label = subject.trim();
    if (label.isNotEmpty && !_subjects.contains(label)) {
      _subjects.add(label);
    }
  }

  Future<void> _pickDateFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedSubject = 'All';
      _selectedDateRange = null;
    });
  }

  // ── Create Flashcard Dialog ────────────────────────────────────
  void _openCreateDialog() {
    final _newCards = <Map<String, dynamic>>[];
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    final subjectCtrl = TextEditingController(text: 'General');
    String? _error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Create Flashcards',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (_newCards.isNotEmpty) {
                    setState(() {
                      for (final card in _newCards) {
                        _flashcards.insert(0, card);
                        _addSubjectIfNeeded(_cardSubject(card));
                      }
                    });
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_newCards.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_newCards.length} card(s) added so far',
                      style: const TextStyle(
                        color: Color(0xFF00BCD4),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Text(
                  'Front (Description)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: frontCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    errorText: _error != null && frontCtrl.text.isEmpty
                        ? _error
                        : null,
                  ),
                  onChanged: (_) => setDialogState(() => _error = null),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Back (Term)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: backCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter term...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    errorText: _error != null && backCtrl.text.isEmpty
                        ? _error
                        : null,
                  ),
                  onChanged: (_) => setDialogState(() => _error = null),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(_newCards.isEmpty ? 'Close' : 'Done'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                if (frontCtrl.text.isNotEmpty && backCtrl.text.isNotEmpty) {
                  _newCards.add(
                    _buildFlashcard(
                      front: frontCtrl.text,
                      back: backCtrl.text,
                      subject: subjectCtrl.text,
                    ),
                  );
                }
                if (_newCards.isNotEmpty) {
                  setState(() {
                    for (final card in _newCards) {
                      _flashcards.insert(0, card);
                      _addSubjectIfNeeded(_cardSubject(card));
                    }
                  });
                }
                Navigator.pop(context);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.navigate_next),
              label: const Text('Next Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                if (frontCtrl.text.trim().isEmpty ||
                    backCtrl.text.trim().isEmpty) {
                  setDialogState(() => _error = 'Both fields are required.');
                  return;
                }
                setDialogState(() {
                  _newCards.add(
                    _buildFlashcard(
                      front: frontCtrl.text.trim(),
                      back: backCtrl.text.trim(),
                    ),
                  );
                  frontCtrl.clear();
                  backCtrl.clear();
                  subjectCtrl.text = 'General';
                  _error = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteFlashcard(int index) {
    if (index < 0 || index >= _flashcards.length) return;

    final card = Map<String, dynamic>.from(_flashcards[index]);

    setState(() {
      _lastDeletedCard = card;
      _flashcards.removeAt(index);
      _recentlyDeleted.removeWhere((item) => item['id'] == card['id']);
      _recentlyDeleted.insert(0, {
        ...card,
        'deletedAt': DateTime.now().toIso8601String(),
      });
      _reviewedCardIds.remove(card['id']);
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Flashcard moved to Recently Deleted.'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: 'Undo', onPressed: _undoLastDelete),
      ),
    );
  }

  void _restoreDeletedCard(String id) {
    final index = _recentlyDeleted.indexWhere((card) => card['id'] == id);
    if (index == -1) return;

    final deleted = _recentlyDeleted[index];
    final card = Map<String, dynamic>.from(deleted)..remove('deletedAt');

    final alreadyActive = _flashcards.any((active) => active['id'] == id);

    setState(() {
      if (!alreadyActive) {
        _flashcards.add(card);
      }
      _recentlyDeleted.removeAt(index);

      if (_lastDeletedCard?['id'] == id) {
        _lastDeletedCard = null;
      }
    });
  }

  void _undoLastDelete() {
    final card = _lastDeletedCard;
    if (card == null) return;

    final id = card['id']?.toString();
    if (id == null) return;

    _restoreDeletedCard(id);
  }

  // ── Delete with confirmation ──────────────────────────────────
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Flashcard?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to delete this flashcard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteFlashcard(index);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Undo last deletion ────────────────────────────────────────
  void _confirmUndo(int index) {
    if (index < 0 || index >= _recentlyDeleted.length) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Restore Flashcard?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Do you want to restore this flashcard to your deck?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);

              // Use the shared restore method if available.
              final card = _recentlyDeleted[index];
              final id = card['id']?.toString();

              if (id != null && id.isNotEmpty) {
                _restoreDeletedCard(id);
              } else {
                // Compatibility with older cards that have no ID.
                final isDuplicate = _flashcards.any(
                  (c) =>
                      c['front'] == card['front'] && c['back'] == card['back'],
                );

                if (isDuplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'This flashcard already exists in your deck.',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                setState(() {
                  _flashcards.add(Map<String, dynamic>.from(card));
                  _recentlyDeleted.removeAt(index);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Flashcard restored!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  // ── Permanent delete ───────────────────────────────────────────
  void _confirmPermanentDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Permanently Delete?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will permanently delete the flashcard. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _recentlyDeleted.removeAt(index));
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  // ── Show recently deleted ──────────────────────────────────────
  void _showRecentlyDeleted() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Recently Deleted',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              _recentlyDeleted.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No recently deleted flashcards.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: _recentlyDeleted.length,
                        itemBuilder: (_, i) {
                          final card = _recentlyDeleted[i];
                          return Card(
                            child: ListTile(
                              title: Text(card['front'] ?? ''),
                              subtitle: Text(card['back'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.restore,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _confirmUndo(i);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _confirmPermanentDelete(i);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Start Study Session ────────────────────────────────────────
  Future<void> _startStudySession() async {
    if (_flashcards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create some flashcards first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<Map<String, dynamic>> deck = List.from(_flashcards);
    if (_isShuffle) deck.shuffle(Random());

    final result = await Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(
        builder: (_) => _StudySession(
          deck: deck,
          onCardReviewed: (cardId) {
            setState(() {
              _reviewedCardIds.add(cardId);
            });
          },
          onFinish: (correct, wrong) {
            // Scores are returned through Navigator.pop().
          },
        ),
      ),
    );

    if (!mounted || result == null) return;

    final correct = result['correct'] ?? 0;
    final wrong = result['wrong'] ?? 0;

    setState(() {
      _correct = correct;
      _wrong = wrong;
    });

    _showResultDialog(correct, wrong);
  }

  void _showResultDialog(int correct, int wrong) {
    final total = correct + wrong;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Session Results',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _resultRow('Correct', correct, Colors.green),
              const SizedBox(height: 8),
              _resultRow('Wrong', wrong, Colors.red),
              const SizedBox(height: 8),
              _resultRow('Total', total, Colors.blueGrey),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Study Again'),
            ),
          ],
        );
      },
    );
  }

  Widget _resultRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6F0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6F0F5),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Flashcards',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            tooltip: 'Recently Deleted',
            onPressed: _showRecentlyDeleted,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_flashcards.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create Flashcard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _openCreateDialog,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: _isShuffle
                          ? const Color(0xFF00BCD4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00BCD4)),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: _isShuffle
                            ? Colors.white
                            : const Color(0xFF00BCD4),
                      ),
                      tooltip: _isShuffle ? 'Shuffle ON' : 'Shuffle OFF',
                      onPressed: () {
                        setState(() {
                          _isShuffle = !_isShuffle;

                          if (_isShuffle) {
                            _flashcards.shuffle(Random());
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),

              if (_isShuffle) ...[
                const SizedBox(height: 6),
                const Text(
                  'Shuffle is ON',
                  style: TextStyle(color: Color(0xFF00BCD4), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ],

            const SizedBox(height: 16),

            if (_flashcards.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_flashcards.length} flashcard(s) ready',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _startStudySession,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_flashcards.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reviewed Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_reviewedCardIds.length}/${_flashcards.length}',
                          style: const TextStyle(
                            color: Color(0xFF00BCD4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _flashcards.isEmpty
                            ? 0
                            : (_reviewedCardIds.length / _flashcards.length)
                                  .clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE0E0E0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00BCD4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Expanded(
              child: _flashcards.isEmpty
                  ? Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 380),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'No flashcards yet.\nTap "Create Flashcard" to get started.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _openCreateDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Create Flashcard'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00BCD4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _flashcards.length,
                      itemBuilder: (context, index) {
                        final card = _flashcards[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFF00BCD4,
                              ).withOpacity(0.2),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF00BCD4),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              card['front'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              card['back'] ?? '',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _confirmDelete(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Study Session Screen
// ══════════════════════════════════════════════════════════════════
class _StudySession extends StatefulWidget {
  final List<Map<String, dynamic>> deck;
  final void Function(int correct, int wrong) onFinish;
  final ValueChanged<String> onCardReviewed;

  const _StudySession({
    required this.deck,
    required this.onFinish,
    required this.onCardReviewed,
  });

  @override
  State<_StudySession> createState() => _StudySessionState();
}

class _StudySessionState extends State<_StudySession> {
  int _index = 0;
  bool _showFront = true;
  int _correct = 0;
  int _wrong = 0;
  bool _answered = false; // ← prevents double scoring

  void _flip() => setState(() => _showFront = !_showFront);

  void _record(bool isCorrect) {
    if (_answered) return; // ← guard against double tap
    final cardId = widget.deck[_index]['id'];
    if (cardId != null) {
      widget.onCardReviewed(cardId.toString());
    }
    setState(() => _answered = true);

    if (isCorrect) {
      _correct++;
    } else {
      _wrong++;
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_index + 1 >= widget.deck.length) {
        Navigator.of(context).pop({'correct': _correct, 'wrong': _wrong});
      } else {
        setState(() {
          _index++;
          _showFront = true;
          _answered = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.deck[_index];
    final total = widget.deck.length;

    return Scaffold(
      backgroundColor: const Color(0xFFD6F0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6F0F5),
        elevation: 0,
        leading: BackButton(
          color: Colors.black,
          onPressed: () {
            Navigator.of(context).pop();
            widget.onFinish(_correct, _wrong);
          },
        ),
        title: Text(
          'Card ${_index + 1} of $total',
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_index + 1) / total,
                minHeight: 8,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00BCD4)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_correct correct',
                  style: const TextStyle(color: Colors.green),
                ),
                Text(
                  '$_wrong wrong',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GestureDetector(
                onTap: _flip,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey('$_index-$_showFront'),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showFront ? 'FRONT' : 'BACK',
                          style: TextStyle(
                            color: _showFront
                                ? const Color(0xFF00BCD4)
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _showFront
                                ? (card['front'] ?? '')
                                : (card['back'] ?? ''),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _answered ? 'Moving to next card...' : 'Tap to flip',
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Wrong'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _answered ? Colors.grey : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _answered ? null : () => _record(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Correct'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _answered ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _answered ? null : () => _record(true),
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
