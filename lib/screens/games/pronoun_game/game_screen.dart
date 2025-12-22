import 'dart:convert';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/story_level.dart';

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

class PronounGameScreen extends StatefulWidget {
  final int levelIndex;
  final String routePrefix;

  const PronounGameScreen({
    super.key,
    required this.levelIndex,
    this.routePrefix = '/pronoun-game',
  });

  @override
  State<PronounGameScreen> createState() => _PronounGameScreenState();
}

class _PronounGameScreenState extends State<PronounGameScreen> {
  List<Word> _words = [];
  Map<int, String> _playerSelections = {};
  final Map<int, String> _correctAnswers = {};

  bool _isLoading = true;
  bool _showResults = false;
  int _correctCount = 0;
  int _errorCount = 0;
  int _scorePercentage = 0;

  StoryLevel? _story;
  int _totalLevels = 0;
  late ConfettiController _confettiController;
  final Random _random = Random();

  // Explanation
  String? _currentExplanationLanguage; // 'en-US' or 'zh-TW'

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
    super.dispose();
  }

  Future<void> _loadLevel() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/pronouns.json',
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

  void _processText(String text) {
    List<Word> words = [];
    int currentIndex = 0;

    final RegExp exp = RegExp(r'(\[[^\]]+\]|\s+|[^\[\s]+)');
    final matches = exp.allMatches(text);

    for (final match in matches) {
      String part = match.group(0)!;
      if (part.isEmpty) continue;

      if (part.startsWith('[') && part.endsWith(']')) {
        // Target block [option1|option2|option3...]
        String content = part.substring(1, part.length - 1); // remove [ ]
        List<String> forms = content.split(RegExp(r'[-|]'));
        if (forms.isNotEmpty) {
          String separator = content.contains('|') ? '|' : '-';
          // If separator is '|', first one is correct. If '-', all are correct (rare for verbs but supported)
          String correctForm = separator == '|' ? forms[0] : "BOTH";

          // Select an initial random form to display
          int initialIndex = _random.nextInt(forms.length);
          String initialText = forms[initialIndex];

          words.add(
            Word(
              text: initialText,
              index: currentIndex,
              isTarget: true,
              options: forms,
              correctForm: correctForm,
            ),
          );

          _correctAnswers[currentIndex] = correctForm;
          currentIndex++;
        }
      } else if (RegExp(r'^\s+$').hasMatch(part)) {
        words.add(
          Word(
            text: part,
            index: currentIndex++,
            isTarget: false,
            options: [],
            correctForm: '',
            isSpace: true,
          ),
        );
      } else {
        // Regular text
        final matchPunc = RegExp(r'^(.*?)([.,!?]*)$').firstMatch(part);
        if (matchPunc != null) {
          String wordText = matchPunc.group(1) ?? '';
          String puncText = matchPunc.group(2) ?? '';

          if (wordText.isNotEmpty) {
            words.add(
              Word(
                text: wordText,
                index: currentIndex++,
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
                index: currentIndex++,
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
      _words = words;
      _playerSelections = {};
    });
  }

  void _handleWordClick(int index) {
    if (_showResults) return;

    final word = _words.firstWhere((w) => w.index == index);
    if (!word.isTarget) return;

    String current = _playerSelections[index] ?? word.text;
    int currentOptionIndex = word.options.indexOf(current);

    // Cycle to next option
    int nextOptionIndex = (currentOptionIndex + 1) % word.options.length;
    String next = word.options[nextOptionIndex];

    setState(() {
      _playerSelections[index] = next;
    });

    // _confettiController.play();
  }

  Future<void> _checkAnswers() async {
    int correct = 0;
    int error = 0;

    for (var word in _words) {
      if (word.isTarget) {
        String selected = _playerSelections[word.index] ?? word.text;
        String correctAns = _correctAnswers[word.index] ?? '';

        if (correctAns == "BOTH") {
          correct++;
        } else {
          if (selected == correctAns) {
            correct++;
          } else {
            error++;
          }
        }
      }
    }

    int total = correct + error;
    int percentage = total > 0 ? ((correct / total) * 100).round() : 0;

    setState(() {
      _correctCount = correct;
      _errorCount = error;
      _scorePercentage = percentage;
      _showResults = true;
      _currentExplanationLanguage = 'zh-TW';
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pronoun-game-${widget.levelIndex}',
      percentage.toString(),
    );

    if (percentage == 100) {
      _confettiController.play();
    }
  }

  void _reset() {
    setState(() {
      _showResults = false;
      _playerSelections = {};

      if (_story != null) {
        _processText(_story!.content);
      }
      _currentExplanationLanguage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_story == null) {
      return const Scaffold(body: Center(child: Text("Level not found")));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_story!.title)),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 0,
                        runSpacing: 12,
                        children: _words.map((word) {
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

                            if (_showResults) {
                              String correctAns =
                                  _correctAnswers[word.index] ?? '';
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
                            if (_showResults &&
                                _correctAnswers[word.index] != "BOTH" &&
                                displayText != _correctAnswers[word.index]) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      displayText,
                                      style: TextStyle(
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected && !_showResults
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
                      const SizedBox(height: 32),

                      if (_showResults &&
                          _currentExplanationLanguage != null) ...[
                        const SizedBox(height: 24),
                        MarkdownBody(
                          data: _currentExplanationLanguage == 'en-US'
                              ? _story!.explanationEnUs
                              : _story!.explanationZhTw,
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
                        const SizedBox(height: 8),
                        Text("Correct: $_correctCount, Wrong: $_errorCount"),
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _currentExplanationLanguage =
                                        (_currentExplanationLanguage == 'en-US')
                                        ? null
                                        : 'en-US';
                                  });
                                },
                                child: const Text('English Explanation'),
                              ),
                            ),
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _currentExplanationLanguage =
                                        (_currentExplanationLanguage == 'zh-TW')
                                        ? null
                                        : 'zh-TW';
                                  });
                                },
                                child: const Text('中文解說'),
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
