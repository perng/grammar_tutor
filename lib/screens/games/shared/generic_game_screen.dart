import 'dart:convert';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/story_level.dart';
import 'package:provider/provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/explanation_dialog.dart';

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

class GenericGameScreen extends StatefulWidget {
  final int levelIndex;
  final String assetPath;
  final String explanationTitle; // Optional override
  final String routePrefix; // For navigation

  const GenericGameScreen({
    super.key,
    required this.levelIndex,
    required this.assetPath,
    this.explanationTitle = '',
    this.routePrefix = '', // Default empty if not passed, but should be passed
  });

  @override
  State<GenericGameScreen> createState() => _GenericGameScreenState();
}

class _GenericGameScreenState extends State<GenericGameScreen> {
  List<Word> _words = [];
  Map<int, String> _playerSelections = {};
  final Map<int, String> _correctAnswers = {};

  bool _isLoading = true;
  bool _showResults = false;
  int _scorePercentage = 0;
  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;

  StoryLevel? _story;
  int _totalLevels = 0;

  final Random _random = Random();

  // Explanation
  // derived from locale in build

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
      final String response = await rootBundle.loadString(widget.assetPath);
      final List<dynamic> data = json.decode(response);
      _totalLevels = data.length;

      if (widget.levelIndex >= 0 && widget.levelIndex < data.length) {
        _story = StoryLevel.fromJson(data[widget.levelIndex]);
        _processText(_story!.content);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading level: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          // If separator is '|', first one is correct. If '-', all are correct (rare but supported)
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
        // Regular text, looking for punctuation split
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

    // Removed confetti play on selection change for better UX
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
      _scorePercentage = percentage;
      _showResults = true;
    });

    // Save progress using the asset path as a uniqueish key base
    // Removing 'assets/data/' and '.json'
    String keyBase = widget.assetPath
        .replaceAll('assets/data/', '')
        .replaceAll('.json', '');
    if (mounted) {
      await Provider.of<ProgressProvider>(
        context,
        listen: false,
      ).updateGameProgress('$keyBase-${widget.levelIndex}', percentage);
    }

    if (percentage == 100 && mounted) {
      _confettiController.play();
    }

    // Auto-scroll to show explanation
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

      if (_story != null) {
        _processText(_story!.content);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Add keys to AppLocalizations for game UI
    final loc = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_story == null) {
      return const Scaffold(body: Center(child: Text("Level not found")));
    }

    final locale = Provider.of<LocaleProvider>(context).locale;
    String explanationContent = '';

    // Determine which explanation to show based on locale
    // zh_CN -> explanationZhCn (fallback to TW)
    // zh_TW -> explanationZhTw
    // else -> explanationEnUs

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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(_story!.title)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.menu_book, size: 20),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                // Construct a path that matches the logic in ExplanationDialog for a specific level
                // It expects a path ending in /[index]
                ExplanationDialog.show(
                  context,
                  widget.assetPath,
                  'dummy/${widget.levelIndex}',
                );
              },
            ),
          ],
        ),
      ),
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
                        runSpacing: 12, // Better spacing for touch targets
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
                                  horizontal: 8, // Larger target
                                  vertical: 4, // Larger target
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

                      if (_showResults) ...[
                        const SizedBox(height: 24),
                        MarkdownBody(
                          data: explanationContent,
                          selectable: true,
                        ),
                        // Add some padding at bottom so content isn't covered by sticky bar
                        const SizedBox(height: 80),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
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
                          "${loc.get('score')}: $_scorePercentage%",
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
                                child: Text(loc.get('try_again')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Next Level Button
                            if (widget.levelIndex < _totalLevels - 1 &&
                                widget.routePrefix.isNotEmpty)
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
                                  child: Text(loc.get('next_level')),
                                ),
                              ),
                          ],
                        ),
                        // explanation buttons removed
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
                            child: Text(
                              loc.get('check_answers'),
                              style: const TextStyle(fontSize: 18),
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
