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
class Word {
  final String text;
  final int index;
  final bool isTarget;
  final List<String> options;
  final String correctForm;
  final bool isSpace;
  final bool isPunctuation;

  Word({
    required this.text,
    required this.index,
    required this.isTarget,
    required this.options,
    required this.correctForm,
    this.isSpace = false,
    this.isPunctuation = false,
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
  List<Word> _currentWords = [];
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
    List<Word> words = [];
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
            Word(
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
          Word(
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
              Word(
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
              Word(
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

  void _handleWordClick(int index) {
    if (_isAnswerChecked) return;

    final word = _currentWords.firstWhere((w) => w.index == index);
    if (!word.isTarget) return;

    String current = _playerSelections[index] ?? word.text;
    int currentOptionIndex = word.options.indexOf(current);
    int nextOptionIndex = (currentOptionIndex + 1) % word.options.length;

    setState(() {
      _playerSelections[index] = word.options[nextOptionIndex];
    });
  }

  void _checkAnswer() {
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

    // Update totals
    _totalCorrectBlanks += correctCount;
    _totalBlanks += blankCount;

    // Determine if this question was "perfect" (optional, for simple tracking)
    _questionResults.add(correctCount == blankCount);

    setState(() {
      _isAnswerChecked = true;
    });

    // Scroll to explanation
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
                  Wrap(
                    spacing: 0,
                    runSpacing: 12,
                    children: _currentWords.map((word) {
                      if (word.isSpace) return const Text(' ');

                      bool isSelected = _playerSelections.containsKey(
                        word.index,
                      );
                      String displayText =
                          _playerSelections[word.index] ?? word.text;

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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                  ),

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
