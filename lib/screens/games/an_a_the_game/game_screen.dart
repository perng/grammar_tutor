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

class AnATheWord {
  final String text;
  final String originalText;
  final int index;
  final bool shouldCapitalizeArticle;

  AnATheWord({
    required this.text,
    required this.originalText,
    required this.index,
    required this.shouldCapitalizeArticle,
  });
}

class AnATheGameScreen extends StatefulWidget {
  final int levelIndex;
  final String routePrefix;

  const AnATheGameScreen({
    super.key,
    required this.levelIndex,
    this.routePrefix = '/an-a-the',
  });

  @override
  State<AnATheGameScreen> createState() => _AnATheGameScreenState();
}

class _AnATheGameScreenState extends State<AnATheGameScreen> {
  List<AnATheWord> _words = [];
  Map<int, String> _correctArticles =
      {}; // Key is the INDEX of the word to which article belongs?
  // React Logic:
  // if (isArticle) {
  //   correctArticles.set(index, ...) -> Index in rawWords array?
  //   Wait, React rawWords.forEach((word, index) => ...)
  //   correctArticles.set(index, word)
  //   words.push({ index: index, ... }) if NOT article.
  //   Wait, correctArticles.set(index, ...) where index is RAW index.
  //   But the loop stores raw index in word struct too.
  //   So let's stick to using "word index" as unique ID.
  //
  //   Actually, in React:
  //   `const correctArticle = gameState.correctArticles.get(word.index - 1);`
  //   So the article at raw `index` belongs to word at raw `index + 1`.
  //   Because "The(0) cat(1)". Article at 0. Word at 1.
  //   So for Word(1), we check Article(0).
  //   We need to preserve RAW indices.

  Map<int, String> _playerSelections =
      {}; // Key is raw index of the WORD effectively.

  bool _isLoading = true;
  bool _showResults = false;
  int _scorePercentage = 0;

  StoryLevel? _story;
  int _totalLevels = 0;
  late ConfettiController _confettiController;
  final ScrollController _scrollController = ScrollController();

  static const Set<String> _namesLower = {
    'annie',
    'wally',
    'paula',
    'peter',
    'kenny',
    'zealand',
    'bobby',
    'rita',
    'willy',
    'olivia',
    // Added names from fruits.json
    'benny',
    'gavin',
    'sally',
    'perry',
    'max',
    'kevin',
    'lulu',
    'charlie',
    'penny',
    'percy',
    'billy',
    'pip',
    'dash',
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
        'assets/data/an_a_the.json',
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
    List<AnATheWord> words = [];
    Map<int, String> correctArticles = {};

    final rawWords = content.split(RegExp(r'\s+'));
    bool isFirstWord = true;
    bool pendingArticleStart = false;

    for (int i = 0; i < rawWords.length; i++) {
      String word = rawWords[i];
      if (word.isEmpty) continue;
      String lower = word.toLowerCase();
      bool isArticle = ['a', 'an', 'the'].contains(lower);

      bool isCurrentStart =
          isFirstWord || (i > 0 && RegExp(r'[.!?]$').hasMatch(rawWords[i - 1]));

      if (isArticle) {
        correctArticles[i] = lower;
        pendingArticleStart = isCurrentStart;
      } else {
        bool shouldCap = isCurrentStart || pendingArticleStart;
        words.add(
          AnATheWord(
            text: _namesLower.contains(lower) ? word : lower,
            originalText: word,
            index: i,
            shouldCapitalizeArticle: shouldCap,
          ),
        );
        pendingArticleStart = false; // Reset after attaching to a noun
      }

      if (!isArticle) isFirstWord = false;
    }

    setState(() {
      _words = words;
      _correctArticles = correctArticles;
      _playerSelections = {};
    });
  }

  void _toggleArticle(int wordIndex) {
    if (_showResults) return;

    final word = _words.firstWhere((w) => w.index == wordIndex);
    final bool cap = word.shouldCapitalizeArticle;

    setState(() {
      String? current = _playerSelections[wordIndex];
      // Cycle: null -> a/A -> an/An -> the/The -> null
      if (current == null) {
        _playerSelections[wordIndex] = cap ? 'A' : 'a';
      } else if (current.toLowerCase() == 'a') {
        _playerSelections[wordIndex] = cap ? 'An' : 'an';
      } else if (current.toLowerCase() == 'an') {
        _playerSelections[wordIndex] = cap ? 'The' : 'the';
      } else {
        _playerSelections.remove(wordIndex);
      }
    });
  }

  Future<void> _checkAnswers() async {
    int correct = 0;
    int error = 0;
    int missed = 0;

    for (var word in _words) {
      // Look for article at word.index - 1
      // React: const correctArticle = gameState.correctArticles.get(word.index - 1);
      // Note raw indices.
      String? correctArt =
          _correctArticles[word.index -
              1]; // This works if spacing is consistent.
      String? selectedArt =
          _playerSelections[word.index]; // Selected stored against word index.

      if (correctArt != null) {
        if (selectedArt != null &&
            selectedArt.toLowerCase() == correctArt.toLowerCase()) {
          correct++;
        } else if (selectedArt == null) {
          missed++;
        } else {
          // Wrong article selected
          missed++; // React logic: "missed" if wrong?
          // React: if (selected === correct) correct++ else { missed.push... score.missed++ }
          // Wait, React:
          /*
            if (correctArticle) {
               if (selectedArticle === correctArticle) {
                  correct++
               } else {
                  missed++ // Wait, if I selected 'the' but correct is 'a', is it missed or error?
                             // React code: gameResults.missed.push(word.index)
               }
            } else if (selectedArticle) {
               error++
            }
           */
          // So if ANY article was expected, and handled incorrectly (wrong one or none), it counts as MISSED/Wrong?
          // Actually if I select WRONG article (e.g. 'the' instead of 'a'), React counts it as MISSED.
          // If I select article where NONE needed, counts as ERROR.
        }
      } else {
        if (selectedArt != null) {
          error++;
        }
      }
    }

    int points = correct - error;
    int totalReq = correct + missed;
    int percentage = totalReq > 0 ? ((points / totalReq) * 100).round() : 0;
    if (percentage < 0) percentage = 0;

    setState(() {
      _scorePercentage = percentage;
      _showResults = true;
    });

    if (mounted) {
      await Provider.of<ProgressProvider>(
        context,
        listen: false,
      ).updateGameProgress('an_a_the-${widget.levelIndex}', percentage);
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
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
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
                          String? selectedArt = _playerSelections[word.index];
                          String? correctArt =
                              _correctArticles[word.index -
                                  1]; // Article before word

                          // Logic to determine if article is sentence start?
                          // Article is at word.index - 1.
                          // If word.index - 1 == 0, then yes.
                          // Or if word at word.index - 2 had punctuation.
                          // To be precise we need raw words list or check prev word.
                          // Simplified: use word.isSentenceStart from React?
                          // React: if (isSentenceStart) ...
                          // React passed isSentenceStart into word.
                          // But my parser logic: isSentenceStart = ...
                          // If article is present, it takes 'isSentenceStart' property effectively?
                          // Let's just assume we want to Capitalize if Selected/Correct is at start of block or follows dot.

                          // Display logic
                          // If selected, show selected.
                          // If results, show correction.

                          bool isCorrect = false;
                          bool isMissed = false;
                          bool isError = false;

                          if (_showResults) {
                            if (correctArt != null) {
                              if (selectedArt != null &&
                                  selectedArt.toLowerCase() ==
                                      correctArt.toLowerCase()) {
                                isCorrect = true;
                              } else {
                                isMissed =
                                    true; // Wrong selection or None selection for required slot
                              }
                            } else {
                              if (selectedArt != null) {
                                isError = true; // Selection where none needed
                              }
                            }
                          }

                          List<Widget> children = [];

                          // Article Widget
                          if (selectedArt != null ||
                              (isMissed && correctArt != null)) {
                            String textToShow = '';
                            Color color = Colors.blue;
                            TextDecoration? decoration;

                            // Helper to optionally capitalize
                            String format(String s) =>
                                word.shouldCapitalizeArticle
                                ? _capitalize(s)
                                : s;

                            if (_showResults) {
                              if (isCorrect) {
                                textToShow = selectedArt!;
                                color = Colors.green;
                              } else if (isMissed) {
                                if (selectedArt != null) {
                                  // Show wrong selection crossed out
                                  children.add(
                                    Text(
                                      "${selectedArt} ", // Already has correct case from toggle
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.red,
                                        decoration: TextDecoration.lineThrough,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                textToShow = format(
                                  correctArt!,
                                ); // Format correct answer
                                color = Colors.orange;
                              } else if (isError) {
                                textToShow =
                                    selectedArt!; // Already has correct case
                                color = Colors.red;
                                decoration = TextDecoration.lineThrough;
                              }
                            } else {
                              textToShow = selectedArt ?? '';
                            }

                            if (textToShow.isNotEmpty) {
                              children.add(
                                Text(
                                  "$textToShow ",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold, // Make article bold
                                    color: color,
                                    decoration: decoration,
                                  ),
                                ),
                              );
                            }
                          }

                          // The Word itself
                          String wordDisplay =
                              word.originalText; // Use original casing?
                          if (selectedArt != null ||
                              (isMissed && correctArt != null)) {
                            // If article precedes, should word allow lowercase?
                            // Unless it's a name.
                            // React: shouldLowercaseWord logic.
                            if (!_namesLower.contains(
                                  word.text.toLowerCase(),
                                ) &&
                                wordDisplay != 'I') {
                              wordDisplay = wordDisplay.toLowerCase();
                            }
                          }

                          children.add(
                            Text(
                              wordDisplay,
                              style: const TextStyle(fontSize: 18, height: 1.5),
                            ),
                          );

                          return GestureDetector(
                            onTap: () => _toggleArticle(word.index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (selectedArt != null && !_showResults)
                                    ? Colors.blue.shade50
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: children,
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
