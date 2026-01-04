import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../models/story_level.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';

// Copy of Word class from generic_game_screen.dart
class MockTestWord {
  final String text;
  final int index;
  final bool isTarget;
  final List<String> options;
  final String correctForm;
  final bool isSpace;
  final bool isPunctuation;

  // Article game specific
  final String originalText;
  final bool shouldCapitalizeArticle;

  MockTestWord({
    required this.text,
    required this.index,
    required this.isTarget,
    this.options = const [],
    this.correctForm = '',
    this.isSpace = false,
    this.isPunctuation = false,
    this.originalText = '',
    this.shouldCapitalizeArticle = false,
  });
}

class MockTestRunnerScreen extends StatefulWidget {
  final List<StoryLevel> questions;

  const MockTestRunnerScreen({super.key, required this.questions});

  @override
  State<MockTestRunnerScreen> createState() => _MockTestRunnerScreenState();
}

class _MockTestRunnerScreenState extends State<MockTestRunnerScreen> {
  int _currentIndex = 0;

  // State for current question
  List<MockTestWord> _currentWords = [];
  Map<int, String> _playerSelections = {};
  Map<int, String> _correctAnswers = {};
  bool _isAnswerChecked = false;

  // Overall progress tracking
  int _totalCorrectBlanks = 0;
  int _totalBlanks = 0;

  // Tracking per question for review (optional)
  final List<bool> _questionResults = [];

  final Random _random = Random();
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
    _loadCurrentQuestion();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCurrentQuestion() {
    setState(() {
      _isAnswerChecked = false;
      _playerSelections = {};
      _correctAnswers = {};
      _currentWords = [];
    });

    if (_currentIndex < widget.questions.length) {
      _processText(widget.questions[_currentIndex].content);
    }
  }

  void _processText(String text) {
    if (widget.questions[_currentIndex].type == 'article') {
      _processArticleText(text);
    } else {
      _processGenericText(text);
    }
  }

  void _processGenericText(String text) {
    List<MockTestWord> words = [];
    int indexCounter = 0;

    final RegExp exp = RegExp(r'(\[[^\]]+\]|\s+|[^\[\s]+)');
    final matches = exp.allMatches(text);

    for (final match in matches) {
      String part = match.group(0)!;
      if (part.isEmpty) continue;

      if (part.startsWith('[') && part.endsWith(']')) {
        String content = part.substring(1, part.length - 1);
        List<String> forms = content.split(RegExp(r'[-|]'));
        if (forms.isNotEmpty) {
          String separator = content.contains('|') ? '|' : '-';
          String correctForm = separator == '|' ? forms[0] : "BOTH";

          int initialIndex = _random.nextInt(forms.length);
          String initialText = forms[initialIndex];

          words.add(
            MockTestWord(
              text: initialText,
              index: indexCounter,
              isTarget: true,
              options: forms,
              correctForm: correctForm,
            ),
          );

          _correctAnswers[indexCounter] = correctForm;
          indexCounter++;
        }
      } else if (RegExp(r'^\s+$').hasMatch(part)) {
        words.add(
          MockTestWord(
            text: part,
            index: indexCounter++,
            isTarget: false,
            options: [],
            correctForm: '',
            isSpace: true,
          ),
        );
      } else {
        final matchPunc = RegExp(r'^(.*?)([.,!?]*)$').firstMatch(part);
        if (matchPunc != null) {
          String wordText = matchPunc.group(1) ?? '';
          String puncText = matchPunc.group(2) ?? '';

          if (wordText.isNotEmpty) {
            words.add(
              MockTestWord(
                text: wordText,
                index: indexCounter++,
                isTarget: false,
                options: [],
                correctForm: wordText,
              ),
            );
          }
          if (puncText.isNotEmpty) {
            words.add(
              MockTestWord(
                text: puncText,
                index: indexCounter++,
                isTarget: false,
                options: [],
                correctForm: puncText,
                isPunctuation: true,
              ),
            );
          }
        }
      }
    }

    setState(() {
      _currentWords = words;
    });
  }

  void _processArticleText(String content) {
    List<MockTestWord> words = [];
    Map<int, String> correctArticles = {};

    final rawWords = content.split(RegExp(r'\s+'));
    bool isFirstWord = true;
    bool pendingArticleStart = false;

    // We use indexCounter to keep keys unique and sequential for the UI
    int indexCounter = 0;

    for (int i = 0; i < rawWords.length; i++) {
      String word = rawWords[i];
      if (word.isEmpty) continue;
      String lower = word.toLowerCase();
      bool isArticle = ['a', 'an', 'the'].contains(lower);

      bool isCurrentStart =
          isFirstWord || (i > 0 && RegExp(r'[.!?]$').hasMatch(rawWords[i - 1]));

      if (isArticle) {
        // Store correct article for the NEXT word.
        // We use indexCounter as the ID for the NEXT word.
        // Since we haven't added the next word yet, its ID will be indexCounter (once we iterate to it, or logically)
        // Wait, if we are at 'The'(i), next is 'cat'(i+1).
        // If we skip 'The', we don't increment indexCounter for it?
        // In GenericGame, every token gets an index.
        // In ArticleGame, only Words get indices.
        // Let's stick to ArticleGame logic: only non-articles get added as words.
        correctArticles[indexCounter] = lower;
        pendingArticleStart = isCurrentStart;
      } else {
        bool shouldCap = isCurrentStart || pendingArticleStart;
        words.add(
          MockTestWord(
            text: _namesLower.contains(lower) ? word : lower,
            originalText: word,
            index: indexCounter, // This is the ID used for selections
            isTarget: true, // All non-article words are potential targets
            shouldCapitalizeArticle: shouldCap,
          ),
        );
        indexCounter++;
        pendingArticleStart = false;
      }

      if (!isArticle) isFirstWord = false;
    }

    setState(() {
      _currentWords = words;
      _correctAnswers = correctArticles;
    });
  }

  void _handleWordClick(int index) {
    if (_isAnswerChecked) return;

    final word = _currentWords.firstWhere((w) => w.index == index);
    if (!word.isTarget) return;

    if (widget.questions[_currentIndex].type == 'article') {
      _handleArticleClick(word);
    } else {
      _handleGenericClick(word);
    }
  }

  void _handleGenericClick(MockTestWord word) {
    String current = _playerSelections[word.index] ?? word.text;
    int currentOptionIndex = word.options.indexOf(current);
    int nextOptionIndex = (currentOptionIndex + 1) % word.options.length;

    setState(() {
      _playerSelections[word.index] = word.options[nextOptionIndex];
    });
  }

  void _handleArticleClick(MockTestWord word) {
    String? current =
        _playerSelections[word.index]; // Actually selected article
    final bool cap = word.shouldCapitalizeArticle;

    setState(() {
      if (current == null) {
        _playerSelections[word.index] = cap ? 'A' : 'a';
      } else if (current.toLowerCase() == 'a') {
        _playerSelections[word.index] = cap ? 'An' : 'an';
      } else if (current.toLowerCase() == 'an') {
        _playerSelections[word.index] = cap ? 'The' : 'the';
      } else {
        _playerSelections.remove(word.index);
      }
    });
  }

  void _checkAnswer() {
    if (widget.questions[_currentIndex].type == 'article') {
      _checkArticleAnswer();
    } else {
      _checkGenericAnswer();
    }
  }

  void _checkGenericAnswer() {
    int correctCount = 0;
    int blankCount = 0;

    for (var word in _currentWords) {
      if (word.isTarget) {
        blankCount++;
        String selected = _playerSelections[word.index] ?? word.text;
        String correctAns = _correctAnswers[word.index] ?? '';

        if (correctAns == "BOTH" || selected == correctAns) {
          correctCount++;
        }
      }
    }
    _finalizeCheck(correctCount, blankCount);
  }

  void _checkArticleAnswer() {
    int correct = 0;
    int error = 0;
    int missed = 0;

    for (var word in _currentWords) {
      String? correctArt = _correctAnswers[word.index];
      String? selectedArt = _playerSelections[word.index];

      if (correctArt != null) {
        if (selectedArt != null &&
            selectedArt.toLowerCase() == correctArt.toLowerCase()) {
          correct++;
        } else {
          missed++;
        }
      } else {
        if (selectedArt != null) {
          error++;
        }
      }
    }

    // Scoring logic for Article Game:
    // Points = Correct - Error.
    // Total = Correct + Missed (number of actual articles needed).
    // But MockTest usually counts "Blanks".
    // Let's adapt to fit "Total Correct / Total Blanks" metaphor.
    // Total Blanks = (Correct + Missed + Error) ? No, Error is extra.
    // Let's say Total Blanks = (Number of slots that NEEDED an article) + (Number of slots that DIDN'T need but GOT one).
    // Effectively, every interaction point counts.
    //
    // Simplified:
    // Correct = correct selections.
    // Total = (slots with correctArt) + (slots without correctArt but with selectedArt).
    // This penalizes errors by increasing the denominator and not the numerator.

    // Or strictly follow game logic: Score = (Correct - Error) / (Correct + Missed).
    // But _totalCorrectBlanks is an integer we sum up.
    // Use "Net Correct" for numerator?
    int netCorrect = correct - error;
    if (netCorrect < 0) netCorrect = 0;
    int totalNeeded = correct + missed; // Total articles actually in the text

    // Wait, if I spam articles everywhere, my score shouldn't just be 0/TotalNeeded. It should reflect badness.
    // But MockTest summary is simple "X / Y".
    // Let's use:
    // Numerator: Correct
    // Denominator: TotalNeeded + Error
    // This ensures 100% is only possible if Correct==TotalNeeded and Error==0.

    _finalizeCheck(correct, totalNeeded + error);
  }

  void _finalizeCheck(int correct, int total) {
    _totalCorrectBlanks += correct;
    _totalBlanks += total;
    _questionResults.add(correct == total && total > 0);

    setState(() {
      _isAnswerChecked = true;
    });

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

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadCurrentQuestion();
      // Scroll back to top
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    } else {
      _finishTest();
    }
  }

  Future<void> _finishTest() async {
    // Save Score
    int score = _totalCorrectBlanks;
    int total = _totalBlanks;
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings =
        prefs.getStringList('mock_test_history') ?? [];

    Map<String, dynamic> result = {
      'timestamp': timestamp,
      'score': score,
      'total': total,
    };

    historyStrings.add(json.encode(result));
    await prefs.setStringList('mock_test_history', historyStrings);

    if (mounted) {
      _showSummaryDialog(score, total);
    }
  }

  void _showSummaryDialog(int score, int total) {
    int percentage = total > 0 ? ((score / total) * 100).round() : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Test Complete"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$percentage%",
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Text("You got $score out of $total blanks correct."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.pop(); // Exit runner
            },
            child: const Text("Finish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final question = widget.questions[_currentIndex];

    // Explanation logic
    final locale = Provider.of<LocaleProvider>(context).locale;
    String explanationContent = '';
    if (locale.languageCode == 'zh') {
      if (locale.countryCode == 'CN' || locale.scriptCode == 'Hans') {
        explanationContent = question.explanationZhCn.isNotEmpty
            ? question.explanationZhCn
            : question.explanationZhTw;
      } else {
        explanationContent = question.explanationZhTw;
      }
    } else {
      explanationContent = question.explanationEnUs;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Question ${_currentIndex + 1} / ${widget.questions.length}",
        ),
        automaticallyImplyLeading: false, // Prevent accidental back
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Confirm quit
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text("Quit Test?"),
                  content: const Text("Progress will not be saved."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(c);
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        "Quit",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    question.title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Question content
                  widget.questions[_currentIndex].type == 'article'
                      ? _buildArticleContent()
                      : _buildGenericContent(),

                  // Explanation
                  if (_isAnswerChecked) ...[
                    const SizedBox(height: 48),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      "Explanation",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: explanationContent,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 80), // Padding
                  ],
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: _isAnswerChecked
                    ? ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _currentIndex < widget.questions.length - 1
                              ? (loc.tryGet('next_question') ?? 'Next Question')
                              : (loc.tryGet('finish') ?? 'Finish'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _checkAnswer,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          (loc.tryGet('check') ?? 'Check'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericContent() {
    return Wrap(
      spacing: 0,
      runSpacing: 12,
      children: _currentWords.map((word) {
        if (word.isSpace) return const Text(' ');

        bool isSelected = _playerSelections.containsKey(word.index);
        String displayText = _playerSelections[word.index] ?? word.text;

        Color textColor = Colors.black;
        TextDecoration? decoration;

        if (word.isTarget) {
          textColor = Colors.blue.shade700;
          decoration = TextDecoration.underline;

          if (_isAnswerChecked) {
            String correctAns = _correctAnswers[word.index] ?? '';
            if (correctAns == "BOTH") {
              textColor = Colors.blue;
              decoration = null;
            } else {
              if (displayText == correctAns) {
                textColor = Colors.green;
                decoration = null;
              } else {
                textColor = Colors.red;
                decoration = TextDecoration.lineThrough;
              }
            }
          }
        }

        if (word.isTarget) {
          if (_isAnswerChecked &&
              _correctAnswers[word.index] != "BOTH" &&
              displayText != _correctAnswers[word.index]) {
            // Show wrong answer struck through + correct answer
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayText,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _correctAnswers[word.index]!,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return GestureDetector(
            onTap: () => _handleWordClick(word.index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected && !_isAnswerChecked
                    ? Colors.blue.shade50
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 18,
                  color: textColor,
                  decoration: decoration,
                  fontWeight: word.isTarget
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        }

        return Text(
          word.text,
          style: const TextStyle(fontSize: 18, height: 1.6),
        );
      }).toList(),
    );
  }

  Widget _buildArticleContent() {
    return Wrap(
      spacing: 0,
      runSpacing: 8,
      children: _currentWords.map((word) {
        String? selectedArt = _playerSelections[word.index];
        String? correctArt = _correctAnswers[word.index];

        bool isCorrect = false;
        bool isMissed = false;
        bool isError = false;

        if (_isAnswerChecked) {
          if (correctArt != null) {
            if (selectedArt != null &&
                selectedArt.toLowerCase() == correctArt.toLowerCase()) {
              isCorrect = true;
            } else {
              isMissed = true;
            }
          } else {
            if (selectedArt != null) {
              isError = true;
            }
          }
        }

        List<Widget> children = [];

        // Helper to optionally capitalize
        String format(String s) =>
            word.shouldCapitalizeArticle ? _capitalize(s) : s;

        // Article Widget
        if (selectedArt != null || (isMissed && correctArt != null)) {
          String textToShow = '';
          Color color = Colors.blue;
          TextDecoration? decoration;

          if (_isAnswerChecked) {
            if (isCorrect) {
              textToShow = selectedArt!;
              color = Colors.green;
            } else if (isMissed) {
              if (selectedArt != null) {
                // Show wrong selection crossed out
                children.add(
                  Text(
                    "${selectedArt} ",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      decoration: TextDecoration.lineThrough,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              textToShow = format(correctArt!); // Format correct answer
              color = Colors.orange;
            } else if (isError) {
              textToShow = selectedArt!;
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
                  fontWeight: FontWeight.bold,
                  color: color,
                  decoration: decoration,
                ),
              ),
            );
          }
        }

        // The Word itself
        String wordDisplay = word.originalText;
        if (selectedArt != null || (isMissed && correctArt != null)) {
          // If article precedes, should word allow lowercase?
          if (!_namesLower.contains(word.text.toLowerCase()) &&
              wordDisplay != 'I') {
            wordDisplay = wordDisplay.toLowerCase();
          }
        }

        children.add(
          Text(wordDisplay, style: const TextStyle(fontSize: 18, height: 1.5)),
        );

        return GestureDetector(
          onTap: () => _handleWordClick(word.index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: (selectedArt != null && !_isAnswerChecked)
                  ? Colors.blue.shade50
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        );
      }).toList(),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// Extension to safely get from app localizations if key might be missing
extension LocalizationExt on AppLocalizations {
  String? tryGet(String key) {
    try {
      return get(key);
    } catch (e) {
      return null;
    }
  }
}
