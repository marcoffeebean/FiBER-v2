import 'dart:math';
import 'package:flutter/material.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final List<Map<String, String>> _flashcards = [];
  final List<Map<String, String>> _recentlyDeleted = [];
  bool _isShuffle = false;
  int _correct = 0;
  int _wrong = 0;

  // ── Create Flashcard Dialog ────────────────────────────────────
  void _openCreateDialog() {
    final List<Map<String, String>> _newCards = [];
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    String? _error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Create Flashcards',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() => _flashcards.addAll(_newCards));
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
                        vertical: 6, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_newCards.length} card(s) added so far',
                      style: const TextStyle(
                          color: Color(0xFF00BCD4),
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Text('Front (Description)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: frontCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter description...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    errorText: _error != null && frontCtrl.text.isEmpty
                        ? _error
                        : null,
                  ),
                  onChanged: (_) => setDialogState(() => _error = null),
                ),
                const SizedBox(height: 14),
                const Text('Back (Term)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: backCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter term...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                  Text(_error!,
                      style:
                          const TextStyle(color: Colors.red, fontSize: 12)),
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
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                if (frontCtrl.text.isNotEmpty && backCtrl.text.isNotEmpty) {
                  _newCards.add({
                    'front': frontCtrl.text.trim(),
                    'back': backCtrl.text.trim(),
                  });
                }
                setState(() => _flashcards.addAll(_newCards));
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
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                if (frontCtrl.text.trim().isEmpty ||
                    backCtrl.text.trim().isEmpty) {
                  setDialogState(
                      () => _error = 'Both fields are required.');
                  return;
                }
                setDialogState(() {
                  _newCards.add({
                    'front': frontCtrl.text.trim(),
                    'back': backCtrl.text.trim(),
                  });
                  frontCtrl.clear();
                  backCtrl.clear();
                  _error = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete with confirmation ───────────────────────────────────
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Flashcard?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to delete this flashcard?'),
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
                  borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _recentlyDeleted.insert(0, _flashcards[index]);
                _flashcards.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Flashcard moved to Recently Deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => _confirmUndo(0),
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Undo with confirmation ─────────────────────────────────────
  void _confirmUndo(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Restore Flashcard?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Do you want to restore this flashcard to your deck?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.pop(context);
              final card = _recentlyDeleted[index];
              // Prevent duplicates
              final isDuplicate = _flashcards.any((c) =>
                  c['front'] == card['front'] &&
                  c['back'] == card['back']);
              if (!isDuplicate) {
                setState(() {
                  _flashcards.add(card);
                  _recentlyDeleted.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Flashcard restored!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This flashcard already exists in your deck.'),
                    backgroundColor: Colors.orange,
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Permanently Delete?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This will permanently delete the flashcard. This action cannot be undone.'),
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
                  borderRadius: BorderRadius.circular(20)),
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
              const Text('Recently Deleted',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              _recentlyDeleted.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No recently deleted flashcards.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54)),
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
                                    icon: const Icon(Icons.restore,
                                        color: Colors.green),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _confirmUndo(i);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_forever,
                                        color: Colors.red),
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
  void _startStudy() {
    if (_flashcards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create some flashcards first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<Map<String, String>> deck = List.from(_flashcards);
    if (_isShuffle) deck.shuffle(Random());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StudySession(
          deck: deck,
          onFinish: (correct, wrong) {
            setState(() {
              _correct = correct;
              _wrong = wrong;
            });
            _showResultDialog(correct, wrong);
          },
        ),
      ),
    );
  }

  void _showResultDialog(int correct, int wrong) {
    final total = correct + wrong;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('📊 Session Results',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _resultRow('✅ Correct', correct, Colors.green),
            const SizedBox(height: 8),
            _resultRow('❌ Wrong', wrong, Colors.red),
            const SizedBox(height: 8),
            _resultRow('📋 Total', total, Colors.blueGrey),
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
              Navigator.pop(context);
              _startStudy();
            },
            child: const Text('Study Again'),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Text('$value',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color)),
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
        title: const Text('Flashcards',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        centerTitle: true,
        actions: [
          if (_recentlyDeleted.isNotEmpty)
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
                          borderRadius: BorderRadius.circular(12)),
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
                    icon: Icon(Icons.shuffle,
                        color: _isShuffle
                            ? Colors.white
                            : const Color(0xFF00BCD4)),
                    tooltip: _isShuffle ? 'Shuffle ON' : 'Shuffle OFF',
                    onPressed: () =>
                        setState(() => _isShuffle = !_isShuffle),
                  ),
                ),
              ],
            ),

            if (_isShuffle) ...[
              const SizedBox(height: 6),
              const Text('🔀 Shuffle is ON',
                  style:
                      TextStyle(color: Color(0xFF00BCD4), fontSize: 12),
                  textAlign: TextAlign.center),
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
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: _startStudy,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_correct > 0 || _wrong > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Last Session',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statChip('✅ $_correct Correct', Colors.green),
                        const SizedBox(width: 8),
                        _statChip('❌ $_wrong Wrong', Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recently deleted button
            if (_recentlyDeleted.isNotEmpty) ...[
              TextButton.icon(
                icon: const Icon(Icons.history, size: 16),
                label: Text(
                    '${_recentlyDeleted.length} recently deleted flashcard(s)'),
                onPressed: _showRecentlyDeleted,
              ),
              const SizedBox(height: 8),
            ],

            Expanded(
              child: _flashcards.isEmpty
                  ? const Center(
                      child: Text(
                        'No flashcards yet.\nTap "Create Flashcard" to get started!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _flashcards.length,
                      itemBuilder: (context, index) {
                        final card = _flashcards[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF00BCD4).withOpacity(0.2),
                              child: Text('${index + 1}',
                                  style: const TextStyle(
                                      color: Color(0xFF00BCD4),
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(card['front'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(card['back'] ?? '',
                                style: const TextStyle(
                                    color: Colors.black54)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
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
      padding:
          const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style:
              TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Study Session Screen
// ══════════════════════════════════════════════════════════════════
class _StudySession extends StatefulWidget {
  final List<Map<String, String>> deck;
  final void Function(int correct, int wrong) onFinish;

  const _StudySession({required this.deck, required this.onFinish});

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
    setState(() => _answered = true);

    if (isCorrect) {
      _correct++;
    } else {
      _wrong++;
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_index + 1 >= widget.deck.length) {
        widget.onFinish(_correct, _wrong);
        Navigator.pop(context);
      } else {
        setState(() {
          _index++;
          _showFront = true;
          _answered = false; // ← reset for next card
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
            // Return current scores when back is pressed
            widget.onFinish(_correct, _wrong);
            Navigator.pop(context);
          },
        ),
        title: Text('Card ${_index + 1} of $total',
            style: const TextStyle(color: Colors.black)),
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
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFF00BCD4)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('✅ $_correct correct',
                    style: const TextStyle(color: Colors.green)),
                Text('❌ $_wrong wrong',
                    style: const TextStyle(color: Colors.red)),
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _showFront
                                ? (card['front'] ?? '')
                                : (card['back'] ?? ''),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _answered
                              ? 'Moving to next card...'
                              : 'Tap to flip',
                          style: const TextStyle(
                              color: Colors.black38, fontSize: 13),
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
                      backgroundColor:
                          _answered ? Colors.grey : Colors.red,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                      backgroundColor:
                          _answered ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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