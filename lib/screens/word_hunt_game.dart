import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../services/data_service.dart';

class WordHuntGame extends StatefulWidget {
  const WordHuntGame({super.key});

  @override
  State<WordHuntGame> createState() => _WordHuntGameState();
}

class WordHuntLevel {
  final int level;
  final int gridSize;
  final int wordCount;
  final int minWordLength;
  final int maxWordLength;
  final int timeLimit;

  const WordHuntLevel({
    required this.level,
    required this.gridSize,
    required this.wordCount,
    required this.minWordLength,
    required this.maxWordLength,
    required this.timeLimit,
  });
}

class _CellPosition {
  final int row;
  final int col;

  const _CellPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is _CellPosition && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

class _GridCell {
  final int row;
  final int col;
  String? letter;

  _GridCell(this.row, this.col, [this.letter]);

  bool get isEmpty => letter == null || letter!.trim().isEmpty;
}

class _WordHuntGameState extends State<WordHuntGame> {
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const List<String> _ignoredWords = [
    'THE',
    'AND',
    'FOR',
    'WITH',
    'THIS',
    'THAT',
    'FROM',
    'ARE',
    'WAS',
    'WERE',
    'HAVE',
    'HAS',
    'YOUR',
    'THEIR',
    'THERE',
    'WOULD',
    'SHOULD',
    'ABOUT',
    'WHICH',
    'WHEN',
    'WHERE',
    'THEN',
    'THEM',
    'THOSE',
    'THROUGH',
  ];

  static const List<WordHuntLevel> _levels = [
    WordHuntLevel(
      level: 1,
      gridSize: 6,
      wordCount: 3,
      minWordLength: 4,
      maxWordLength: 6,
      timeLimit: 180,
    ),
    WordHuntLevel(
      level: 2,
      gridSize: 7,
      wordCount: 4,
      minWordLength: 4,
      maxWordLength: 7,
      timeLimit: 200,
    ),
    WordHuntLevel(
      level: 3,
      gridSize: 8,
      wordCount: 5,
      minWordLength: 4,
      maxWordLength: 8,
      timeLimit: 220,
    ),
    WordHuntLevel(
      level: 4,
      gridSize: 9,
      wordCount: 6,
      minWordLength: 5,
      maxWordLength: 9,
      timeLimit: 240,
    ),
    WordHuntLevel(
      level: 5,
      gridSize: 10,
      wordCount: 7,
      minWordLength: 5,
      maxWordLength: 10,
      timeLimit: 260,
    ),
  ];

  final Random _random = Random();
  final List<_CellPosition> _selectedPositions = [];
  final Set<String> _foundWords = <String>{};
  final Map<String, Set<_CellPosition>> _foundWordCells =
      <String, Set<_CellPosition>>{};

  List<String> _targetWords = [];
  Map<String, List<_CellPosition>> _wordPositions = {};
  List<List<_GridCell>> _grid = [];

  Timer? _gameTimer;
  int _currentLevel = 1;
  int _score = 0;
  int _secondsElapsed = 0;
  bool _invalidModule = false;
  String _currentWord = '';
  bool _sessionLogged = false;

  @override
  void initState() {
    super.initState();
    DataService.moduleUpdateNotifier.addListener(_onModuleUpdated);
    _loadLevel(1);
    _startTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    DataService.moduleUpdateNotifier.removeListener(_onModuleUpdated);
    super.dispose();
  }

  void _onModuleUpdated() {
    _gameTimer?.cancel();
    _loadLevel(1, restartTimer: true);
  }

  WordHuntLevel get _currentLevelConfig {
    return _levels.firstWhere(
      (level) => level.level == _currentLevel,
      orElse: () => _levels.first,
    );
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _invalidModule) return;

      final timeLimit = _currentLevelConfig.timeLimit;
      if (_secondsElapsed >= timeLimit) {
        _gameTimer?.cancel();
        if (mounted) {
          setState(() {
            _selectedPositions.clear();
            _currentWord = '';
          });
          _showLevelTimeoutDialog();
        }
        return;
      }

      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _loadLevel(int levelNumber, {bool restartTimer = false}) {
    final safeLevel = levelNumber.clamp(1, _levels.length);
    _currentLevel = safeLevel;
    _secondsElapsed = 0;
    _score = 0;
    _selectedPositions.clear();
    _currentWord = '';
    _foundWords.clear();
    _foundWordCells.clear();
    _wordPositions.clear();
    _sessionLogged = false;

    final level = _getLevel(safeLevel);
    if (level == null) {
      _invalidModule = true;
      _targetWords = [];
      _grid = _buildEmptyGrid(6);
      if (restartTimer) _startTimer();
      if (mounted) setState(() {});
      return;
    }

    final words = _extractWordsForLevel(level);
    if (words.isEmpty) {
      _invalidModule = true;
      _targetWords = [];
      _grid = _buildEmptyGrid(level.gridSize);
      if (restartTimer) _startTimer();
      if (mounted) setState(() {});
      return;
    }

    final generated = _generateGridForWords(words, level.gridSize);
    if (generated == null) {
      _invalidModule = true;
      _targetWords = [];
      _grid = _buildEmptyGrid(level.gridSize);
      if (restartTimer) _startTimer();
      if (mounted) setState(() {});
      return;
    }

    _invalidModule = false;
    _targetWords = words;
    _grid = generated;
    _recalculateWordPositions();

    if (restartTimer || _gameTimer == null) {
      _startTimer();
    }

    if (mounted) setState(() {});
  }

  WordHuntLevel? _getLevel(int levelNumber) {
    try {
      return _levels.firstWhere((level) => level.level == levelNumber);
    } catch (_) {
      return null;
    }
  }

  List<String> _extractWordsForLevel(WordHuntLevel level) {
    final validWords = <String>{};
    final modules = DataService.modules;

    if (modules.isEmpty) {
      return const [];
    }

    for (final module in modules) {
      final content = module.content.toUpperCase();
      final tokens = content
          .split(RegExp(r'[^A-Z]+'))
          .where((value) => value.isNotEmpty)
          .map((value) => value.trim())
          .where((value) => value.length >= level.minWordLength)
          .where((value) => value.length <= level.maxWordLength)
          .where((value) => value.length <= level.gridSize)
          .where((value) => !value.contains(RegExp(r'[^A-Z]')))
          .where((value) => !value.startsWith(RegExp(r'[0-9]')))
          .where((value) => !_ignoredWords.contains(value))
          .toList();

      for (final token in tokens) {
        if (token.length < level.minWordLength ||
            token.length > level.maxWordLength) {
          continue;
        }
        if (token.length > level.gridSize) {
          continue;
        }
        if (token.length < 2) {
          continue;
        }
        validWords.add(token);
      }
    }

    final words = validWords.toList();
    words.sort((a, b) {
      if (a.length == b.length) return a.compareTo(b);
      return b.length.compareTo(a.length);
    });

    if (words.length < level.wordCount) {
      return const [];
    }

    return words.take(level.wordCount).toList();
  }

  List<List<_GridCell>> _buildEmptyGrid(int size) {
    return List.generate(
      size,
      (row) => List.generate(size, (col) => _GridCell(row, col, null)),
    );
  }

  String _randomLetter() => _alphabet[_random.nextInt(_alphabet.length)];

  List<List<_GridCell>>? _generateGridForWords(
    List<String> words,
    int gridSize,
  ) {
    final shuffledWords = [...words]..shuffle(_random);

    for (int attempt = 0; attempt < 300; attempt++) {
      final grid = _buildEmptyGrid(gridSize);
      bool placedAll = true;

      for (final word in shuffledWords) {
        final placement = _findPlacementForWord(grid, word);
        if (placement == null) {
          placedAll = false;
          break;
        }

        for (int index = 0; index < placement.length; index++) {
          final point = placement[index];
          grid[point.row][point.col].letter = word[index];
        }
      }

      if (!placedAll) {
        continue;
      }

      for (int row = 0; row < gridSize; row++) {
        for (int col = 0; col < gridSize; col++) {
          if (grid[row][col].letter == null) {
            grid[row][col].letter = _randomLetter();
          }
        }
      }

      final allWordsPresent = shuffledWords.every(
        (word) => _findWordPositionsInGrid(grid, word).isNotEmpty,
      );

      if (allWordsPresent) {
        return grid;
      }
    }

    return null;
  }

  List<_CellPosition>? _findPlacementForWord(
    List<List<_GridCell>> grid,
    String word,
  ) {
    final directions = const <_CellPosition>[
      _CellPosition(0, 1),
      _CellPosition(0, -1),
      _CellPosition(1, 0),
      _CellPosition(-1, 0),
      _CellPosition(1, 1),
      _CellPosition(-1, -1),
      _CellPosition(1, -1),
      _CellPosition(-1, 1),
    ];

    final size = grid.length;
    final candidateStarts = <_CellPosition>[];
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        candidateStarts.add(_CellPosition(row, col));
      }
    }

    candidateStarts.shuffle(_random);
    for (final start in candidateStarts) {
      for (final direction in directions) {
        final endRow = start.row + direction.row * (word.length - 1);
        final endCol = start.col + direction.col * (word.length - 1);
        if (endRow < 0 || endRow >= size || endCol < 0 || endCol >= size) {
          continue;
        }

        final positions = <_CellPosition>[];
        var valid = true;
        for (int index = 0; index < word.length; index++) {
          final row = start.row + direction.row * index;
          final col = start.col + direction.col * index;
          final cell = grid[row][col];
          final character = word[index];

          if (cell.letter != null && cell.letter != character) {
            valid = false;
            break;
          }

          positions.add(_CellPosition(row, col));
        }

        if (valid) {
          return positions;
        }
      }
    }

    return null;
  }

  List<_CellPosition> _findWordPositionsInGrid(
    List<List<_GridCell>> grid,
    String word,
  ) {
    final directions = const <_CellPosition>[
      _CellPosition(0, 1),
      _CellPosition(0, -1),
      _CellPosition(1, 0),
      _CellPosition(-1, 0),
      _CellPosition(1, 1),
      _CellPosition(1, -1),
      _CellPosition(-1, 1),
      _CellPosition(-1, -1),
    ];

    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid.length; col++) {
        if ((grid[row][col].letter ?? '').toUpperCase() != word[0]) {
          continue;
        }

        for (final direction in directions) {
          final positions = <_CellPosition>[];
          var valid = true;

          for (int index = 0; index < word.length; index++) {
            final nextRow = row + direction.row * index;
            final nextCol = col + direction.col * index;
            if (nextRow < 0 ||
                nextRow >= grid.length ||
                nextCol < 0 ||
                nextCol >= grid.length) {
              valid = false;
              break;
            }

            final cellLetter = grid[nextRow][nextCol].letter ?? '';
            if (cellLetter.toUpperCase() != word[index]) {
              valid = false;
              break;
            }
            positions.add(_CellPosition(nextRow, nextCol));
          }

          if (valid) {
            return positions;
          }
        }
      }
    }

    return const [];
  }

  void _recalculateWordPositions() {
    final newMap = <String, List<_CellPosition>>{};
    for (final word in _targetWords) {
      final positions = _findWordPositions(word);
      if (positions.isNotEmpty) {
        newMap[word] = positions;
      }
    }
    _wordPositions = newMap;
  }

  List<_CellPosition> _findWordPositions(String word) {
    return _findWordPositionsInGrid(_grid, word);
  }

  int _scoreForWord(String word) => word.length * 10;

  bool _isPositionInsideGrid(_CellPosition position) {
    return position.row >= 0 &&
        position.row < _grid.length &&
        position.col >= 0 &&
        position.col < _grid.length;
  }

  bool _canExtendSelection(_CellPosition candidate) {
    if (_selectedPositions.isEmpty) return true;

    final last = _selectedPositions.last;
    if (last == candidate) return false;
    if (_selectedPositions.contains(candidate)) return false;

    final deltaRow = candidate.row - last.row;
    final deltaCol = candidate.col - last.col;

    if (deltaRow.abs() > 1 || deltaCol.abs() > 1) {
      return false;
    }

    if (_selectedPositions.length == 1) {
      final first = _selectedPositions.first;
      final rowDelta = candidate.row - first.row;
      final colDelta = candidate.col - first.col;
      return rowDelta == 0 || colDelta == 0 || rowDelta.abs() == colDelta.abs();
    }

    final previous = _selectedPositions[_selectedPositions.length - 2];
    final previousDeltaRow = last.row - previous.row;
    final previousDeltaCol = last.col - previous.col;
    final candidateDeltaRow = candidate.row - last.row;
    final candidateDeltaCol = candidate.col - last.col;

    final previousDirection = _directionVector(
      previousDeltaRow,
      previousDeltaCol,
    );
    final candidateDirection = _directionVector(
      candidateDeltaRow,
      candidateDeltaCol,
    );

    return previousDirection == candidateDirection;
  }

  _CellPosition _directionVector(int deltaRow, int deltaCol) {
    final row = deltaRow == 0 ? 0 : (deltaRow > 0 ? 1 : -1);
    final col = deltaCol == 0 ? 0 : (deltaCol > 0 ? 1 : -1);
    return _CellPosition(row, col);
  }

  void _handleSelectionEnd() {
    if (_selectedPositions.isEmpty) return;

    final selectedWord = _currentWord.trim().toUpperCase();
    final reversedWord = selectedWord.split('').reversed.join();
    final candidates = <String>{selectedWord, reversedWord};

    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;

      if (_foundWords.contains(candidate)) {
        setState(() {
          _clearSelection();
        });
        _showFeedback('Already found', Colors.orange);
        return;
      }

      if (_targetWords.contains(candidate)) {
        final wordPoints = _scoreForWord(candidate);
        final positions =
            _wordPositions[candidate] ??
            _selectedPositions.map((p) => _CellPosition(p.row, p.col)).toList();

        setState(() {
          _foundWords.add(candidate);
          _foundWordCells[candidate] = positions.toSet();
          _score += wordPoints;
          _selectedPositions.clear();
          _currentWord = '';
        });

        if (!_sessionLogged) {
          DataService.addGamePlayed();
          _sessionLogged = true;
        }

        if (_foundWords.length == _targetWords.length) {
          _showLevelCompleteDialog();
        } else {
          _showFeedback('✓ $candidate', Colors.green.shade700);
        }
        return;
      }
    }

    setState(() {
      _clearSelection();
    });
    _showFeedback('✕ Try again', Colors.red);
  }

  void _showFeedback(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _showLevelCompleteDialog() {
    _gameTimer?.cancel();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Level Complete!'),
        content: Text(
          'Level: $_currentLevel\nScore: $_score\nTime: $_formattedTime',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final nextLevel = _currentLevel + 1;
              if (nextLevel <= _levels.length) {
                _loadLevel(nextLevel, restartTimer: true);
              } else {
                _showFeedback('All levels complete!', Colors.green);
              }
            },
            child: const Text('Next Level'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLevel(_currentLevel, restartTimer: true);
            },
            child: const Text('Restart Level'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showLevelTimeoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Time Up!'),
        content: Text('Level $_currentLevel timed out.\nTry again!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLevel(_currentLevel, restartTimer: true);
            },
            child: const Text('Restart Level'),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    final minutes = _secondsElapsed ~/ 60;
    final seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  _CellPosition? _cellFromLocalPosition(Offset localPosition, double cellSize) {
    final row = (localPosition.dy / cellSize).floor();
    final col = (localPosition.dx / cellSize).floor();

    if (row < 0 || col < 0) return null;
    if (row >= _grid.length || col >= _grid.length) return null;

    return _CellPosition(row, col);
  }

  void _clearSelection() {
    _selectedPositions.clear();
    _currentWord = '';
  }

  void _beginSelection(_CellPosition cell) {
    if (!_isPositionInsideGrid(cell)) return;
    final cellLetter = _grid[cell.row][cell.col].letter;
    if (cellLetter == null || cellLetter.trim().isEmpty) return;

    _selectedPositions
      ..clear()
      ..add(cell);
    _currentWord = cellLetter.toUpperCase();
    setState(() {});
  }

  void _updateSelection(_CellPosition cell) {
    if (!_isPositionInsideGrid(cell)) return;
    if (_selectedPositions.isEmpty) return;
    final last = _selectedPositions.last;
    if (last == cell || _selectedPositions.contains(cell)) return;

    final cellLetter = _grid[cell.row][cell.col].letter;
    if (cellLetter == null || cellLetter.trim().isEmpty) return;
    if (!_canExtendSelection(cell)) return;

    _selectedPositions.add(cell);
    _currentWord = _selectedPositions
        .map((position) => _grid[position.row][position.col].letter ?? '')
        .join()
        .toUpperCase();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: const BackButton(),
        title: const Text(
          'Word Hunt',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: _invalidModule
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Not enough suitable words for this level.\nPlease upload a module with more content.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            )
          : DataService.modules.isEmpty
          ? Center(
              child: Text(
                'No modules uploaded yet.\nAsk your teacher to upload one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final gridSize = _grid.length;
                final safeWidth = constraints.maxWidth - 32;
                final cellSize = (safeWidth / gridSize).clamp(26.0, 52.0);
                final boardSize = cellSize * gridSize;

                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Level $_currentLevel',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _infoCard('Score', '$_score', context),
                            const SizedBox(width: 8),
                            _infoCard('Time', _formattedTime, context),
                            const SizedBox(width: 8),
                            _infoCard(
                              'Words',
                              '${_foundWords.length}/${_targetWords.length}',
                              context,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (details) {
                                final cell = _cellFromLocalPosition(
                                  details.localPosition,
                                  cellSize,
                                );
                                if (cell != null) {
                                  _beginSelection(cell);
                                }
                              },
                              onPanUpdate: (details) {
                                final cell = _cellFromLocalPosition(
                                  details.localPosition,
                                  cellSize,
                                );
                                if (cell != null) {
                                  _updateSelection(cell);
                                }
                              },
                              onPanEnd: (_) => _handleSelectionEnd(),
                              onPanCancel: () => _handleSelectionEnd(),
                              child: SizedBox(
                                width: boardSize,
                                height: boardSize,
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: gridSize,
                                        crossAxisSpacing: 3,
                                        mainAxisSpacing: 3,
                                        childAspectRatio: 1,
                                      ),
                                  itemCount: gridSize * gridSize,
                                  itemBuilder: (context, index) {
                                    final row = index ~/ gridSize;
                                    final col = index % gridSize;
                                    final cell = _grid[row][col];
                                    final key = _CellPosition(row, col);
                                    final isSelected = _selectedPositions
                                        .contains(key);
                                    final foundCount = _foundWordCells.values
                                        .where(
                                          (positions) =>
                                              positions.contains(key),
                                        )
                                        .length;

                                    final cellColor = isSelected
                                        ? Theme.of(context).colorScheme.primary
                                              .withOpacity(0.18)
                                        : foundCount > 0
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primary.withOpacity(
                                            0.18 + (foundCount * 0.12),
                                          )
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest;

                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cellColor,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : foundCount > 0
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.7)
                                              : Theme.of(context).dividerColor,
                                          width: isSelected || foundCount > 0
                                              ? 1.5
                                              : 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        cell.letter ?? '',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_currentWord.isNotEmpty)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _currentWord,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          'Words to find',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._targetWords.map((word) {
                          final found = _foundWords.contains(word);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: found
                                  ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withOpacity(0.35)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              word,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: found
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                decoration: found
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _infoCard(String label, String value, BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
