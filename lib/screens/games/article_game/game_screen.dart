import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/story_level.dart';
import 'package:provider/provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/progress_provider.dart';

class ArticleWord {
  final String text;
  final int index;
  final bool isSentenceStart;
  final bool isFirstNonArticleWord;

  ArticleWord({
    required this.text,
    required this.index,
    required this.isSentenceStart,
    required this.isFirstNonArticleWord,
  });
}

class ArticleGameScreen extends StatefulWidget {
  final int levelIndex;
  final String routePrefix;

  const ArticleGameScreen({
    super.key,
    required this.levelIndex,
    this.routePrefix = '/article-game',
  });

  @override
  State<ArticleGameScreen> createState() => _ArticleGameScreenState();
}

class _ArticleGameScreenState extends State<ArticleGameScreen> {
  List<ArticleWord> _words = [];
  Set<int> _correctThePositions = {};
  Set<int> _playerSelections = {};

  bool _isLoading = true;
  bool _showResults = false;
  int _scorePercentage = 0;

  StoryLevel? _story;
  int _totalLevels = 0;
  late ConfettiController _confettiController;
  final ScrollController _scrollController = ScrollController();

  static const Set<String> _names = {
    'Cappy',
    'Sammy',
    'Ollie',
    'Olly',
    'Penny',
    'Toby',
    'Gary',
    'Lily',
    'Squeaky',
    'Bella',
    'Max',
    'Benny',
    'Milo',
    'Rosie',
    'Tina',
    'Freddy',
    'Daisy',
    'Timmy',
    'Hugo',
    'Charlie',
    'I',
  };

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadLevel();
    _saveLastPlayed();
  }

  Future<void> _saveLastPlayed() async {
    if (widget.routePrefix.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_played_index_${widget.routePrefix}',
        widget.levelIndex,
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLevel() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/articles.json',
      );
      final List<dynamic> data = json.decode(response);
      _totalLevels = data.length;

      if (widget.levelIndex >= 0 && widget.levelIndex < data.length) {
        _story = StoryLevel.fromJson(data[widget.levelIndex]);
        _processText(_story!.content);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading level: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processText(String content) {
    List<ArticleWord> words = [];
    Set<int> correctPositions = {};

    // Split by whitespace
    final rawWords = content.split(RegExp(r'\s+'));
    bool isFirstWord = true;

    // React Logic Migration
    // Need to track rawWords index for punctuation checks?
    // Using simple iteration.

    for (int i = 0; i < rawWords.length; i++) {
      String word = rawWords[i];
      if (word.isEmpty) continue;

      bool isThe = word.toLowerCase() == 'the';
      // Check if sentence start.
      // React: isFirstWord || (index > 0 && /[.!?]$/.test(rawWords[index - 1]))
      // Note: rawWords[i-1] might be empty if double spaces? split(RegExp(r'\s+')) usually handles empty if using trim/non-empty filter.
      // Dart split might include empty strings?

      bool isSentenceStart =
          isFirstWord || (i > 0 && RegExp(r'[.!?]$').hasMatch(rawWords[i - 1]));

      // React: isFirstNonArticleWord check ...
      bool isFirstNonArticleWord =
          i > 0 &&
          rawWords[i - 1].toLowerCase() == 'the' &&
          (i == 1 || RegExp(r'[.!?]$').hasMatch(rawWords[i - 2]));

      if (!isThe) {
        words.add(
          ArticleWord(
            text: word,
            index: words.length,
            isSentenceStart: isSentenceStart,
            isFirstNonArticleWord: isFirstNonArticleWord,
          ),
        );
      }

      if (isThe) {
        correctPositions.add(words.length);
        // Note: if "the" is at start of sentence, the NEXT word (which is added to words)
        // technically isn't "isSentenceStart" in its own right in terms of punctuation?
        // But "The cat". "The" is sentence start. "cat" is NOT.
        // In React:
        /*
             if (isThe) {
                correctThePositions.add(words.length);
                if (isSentenceStart) {
                   sentenceStarts.add(words.length); // Used for capitalization
                }
             }
          */
        // I didn't replicate sentenceStarts set but I can derive capitalization.
      }

      if (!isThe) {
        isFirstWord = false;
      }
    }

    setState(() {
      _words = words;
      _correctThePositions = correctPositions;
      _playerSelections = {};
    });
  }

  void _toggleThe(int index) {
    if (_showResults) return;

    setState(() {
      if (_playerSelections.contains(index)) {
        _playerSelections.remove(index);
      } else {
        _playerSelections.add(index);
      }
    });
    // Sound/Haptic feedback here?
  }

  Future<void> _checkAnswers() async {
    int correct = 0;
    int error = 0;
    int missed = 0;

    // React Logic:
    /*
       words.forEach(word => {
          if (correct.has(idx)) {
             if (selected.has(idx)) correct++
             else missed++
          } else if (selected.has(idx)) {
             error++
          }
       })
    */
    // Wait, do we iterate words? "the" is attached to a word index.
    // Yes, for each word index 0..N-1.
    // Also need to check if there is a "the" at the VERY END? No, "the" is always followed by noun.

    for (var word in _words) {
      int idx = word.index;
      if (_correctThePositions.contains(idx)) {
        if (_playerSelections.contains(idx)) {
          correct++;
        } else {
          missed++;
        }
      } else if (_playerSelections.contains(idx)) {
        error++;
      }
    }

    // Point calc
    int points = correct - error;
    int totalThes = correct + missed;
    int percentage = totalThes > 0 ? ((points / totalThes) * 100).round() : 0;
    if (percentage < 0) percentage = 0;

    setState(() {
      _scorePercentage = percentage;
      _showResults = true;
    });

    if (mounted) {
      await Provider.of<ProgressProvider>(
        context,
        listen: false,
      ).updateGameProgress('articles-${widget.levelIndex}', percentage);
    }

    if (percentage == 100) {
      _confettiController.play();
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _reset() {
    setState(() {
      _showResults = false;
      _playerSelections = {};
    });
    // Re-process is idempotent so no need unless we reshuffle (not applicable here)
  }

  String _getDisplayWord(ArticleWord word, bool isSelected, bool isMissed) {
    if (_names.contains(word.text)) return word.text;

    // If "the" is prepended (selected or missed), usually the word becomes lowercase
    // UNLESS it is a name or 'I' etc.
    // React: const shouldLowercaseWord = !NAMES.has(word.text) && (!(word.isSentenceStart) || isSelected || isMissed);
    // If isSelected (The is added), then word should be lowercased?
    // "The Cat" -> "The cat"

    // But word.isSentenceStart track if THIS WORD started the sentence (without 'the').
    // If 'the' is added, 'the' starts the sentence.

    // Simplification:
    if (isSelected || isMissed) {
      // "The" is present. Word should lowercase unless Name.
      return word.text.toLowerCase();
    }

    // "The" is NOT present.
    // If it was originally preceded by a sentence-starting "The", it is now the start.
    if (word.isFirstNonArticleWord) {
      if (word.text.isNotEmpty) {
        return word.text[0].toUpperCase() + word.text.substring(1);
      }
    }

    // Otherwise return as is
    return word.text;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_story == null) {
      return const Scaffold(body: Center(child: Text("Level not found")));
    }

    final locale = Provider.of<LocaleProvider>(context).locale;
    String explanationContent = '';

    if (locale.languageCode == 'zh') {
      if (locale.countryCode == 'CN' || locale.scriptCode == 'Hans') {
        explanationContent = _story!.explanationZhCn.isNotEmpty
            ? _story!.explanationZhCn
            : _story!.explanationZhTw;
      } else {
        explanationContent = _story!.explanationZhTw;
      }
    } else {
      explanationContent = _story!.explanationEnUs;
    }

    return Scaffold(
      appBar: AppBar(title: Text(_story!.title)),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 0,
                        runSpacing: 8,
                        children: _words.map((word) {
                          bool isSelected = _playerSelections.contains(
                            word.index,
                          );
                          bool isCorrectPos = _correctThePositions.contains(
                            word.index,
                          );
                          bool isError =
                              _showResults && !isCorrectPos && isSelected;
                          bool isMissed =
                              _showResults && isCorrectPos && !isSelected;

                          String prefix = "the ";
                          bool capThe = (word.index == 0);
                          if (word.index > 0) {
                            ArticleWord prev = _words[word.index - 1];
                            if (RegExp(r'[.!?]$').hasMatch(prev.text)) {
                              capThe = true;
                            }
                          }
                          if (capThe) prefix = "The ";

                          return GestureDetector(
                            onTap: () => _toggleThe(word.index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: (isSelected && !_showResults)
                                    ? Colors.blue.shade50
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected || isMissed)
                                    Text(
                                      prefix,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _showResults
                                            ? (isError
                                                  ? Colors.red
                                                  : (isMissed
                                                        ? Colors.orange
                                                        : Colors.green))
                                            : Colors.blue,
                                        decoration: isError
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  Text(
                                    _getDisplayWord(word, isSelected, isMissed),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      // Explanation area if results shown
                      if (_showResults) ...[
                        const SizedBox(height: 32),
                        MarkdownBody(
                          data: explanationContent,
                          selectable: true,
                        ),
                        // Bottom padding for sticky bar
                        const SizedBox(height: 80),
                      ],
                    ],
                  ),
                ),
              ),
              // Sticky Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showResults) ...[
                        Text(
                          "Score: $_scorePercentage%",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _reset,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Try Again'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.levelIndex < _totalLevels - 1)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.pushReplacement(
                                      '${widget.routePrefix}/${widget.levelIndex + 1}',
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Next Level'),
                                ),
                              ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _checkAnswers,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Check Answers',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}
