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
import '../../theme/app_colors.dart';

class MockTestWord {
  final String text;
  final int index;
  final bool isTarget;
  final List<String> options;
  final String correctForm;
  final bool isSpace;
  final bool isPunctuation;
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
  List<MockTestWord> _currentWords = [];
  Map<int, String> _playerSelections = {};
  Map<int, String> _correctAnswers = {};
  bool _isAnswerChecked = false;

  int _totalCorrectBlanks = 0;
  int _totalBlanks = 0;
  final List<bool> _questionResults = [];

  final Random _random = Random();
  final ScrollController _scrollController = ScrollController();

  static const Set<String> _namesLower = {
    'annie', 'wally', 'paula', 'peter', 'kenny', 'zealand', 'bobby', 'rita',
    'willy', 'olivia', 'benny', 'gavin', 'sally', 'perry', 'max', 'kevin',
    'lulu', 'charlie', 'penny', 'percy', 'billy', 'pip', 'dash',
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

          words.add(MockTestWord(
            text: initialText, index: indexCounter, isTarget: true,
            options: forms, correctForm: correctForm,
          ));
          _correctAnswers[indexCounter] = correctForm;
          indexCounter++;
        }
      } else if (RegExp(r'^\s+$').hasMatch(part)) {
        words.add(MockTestWord(
          text: part, index: indexCounter++, isTarget: false,
          options: [], correctForm: '', isSpace: true,
        ));
      } else {
        final matchPunc = RegExp(r'^(.*?)([.,!?]*)$').firstMatch(part);
        if (matchPunc != null) {
          String wordText = matchPunc.group(1) ?? '';
          String puncText = matchPunc.group(2) ?? '';
          if (wordText.isNotEmpty) {
            words.add(MockTestWord(
              text: wordText, index: indexCounter++, isTarget: false,
            ));
          }
          if (puncText.isNotEmpty) {
            words.add(MockTestWord(
              text: puncText, index: indexCounter++, isTarget: false,
              isPunctuation: true,
            ));
          }
        }
      }
    }
    setState(() => _currentWords = words);
  }

  void _processArticleText(String content) {
    List<MockTestWord> words = [];
    Map<int, String> correctArticles = {};
    final rawWords = content.split(RegExp(r'\s+'));
    bool isFirstWord = true;
    bool pendingArticleStart = false;
    int indexCounter = 0;

    for (int i = 0; i < rawWords.length; i++) {
      String word = rawWords[i];
      if (word.isEmpty) continue;
      String lower = word.toLowerCase();
      bool isArticle = ['a', 'an', 'the'].contains(lower);
      bool isCurrentStart =
          isFirstWord || (i > 0 && RegExp(r'[.!?]$').hasMatch(rawWords[i - 1]));

      if (isArticle) {
        correctArticles[indexCounter] = lower;
        pendingArticleStart = isCurrentStart;
      } else {
        bool shouldCap = isCurrentStart || pendingArticleStart;
        words.add(MockTestWord(
          text: _namesLower.contains(lower) ? word : lower,
          originalText: word, index: indexCounter, isTarget: true,
          shouldCapitalizeArticle: shouldCap,
        ));
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
    setState(() => _playerSelections[word.index] = word.options[nextOptionIndex]);
  }

  void _handleArticleClick(MockTestWord word) {
    String? current = _playerSelections[word.index];
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
    int correctCount = 0, blankCount = 0;
    for (var word in _currentWords) {
      if (word.isTarget) {
        blankCount++;
        String selected = _playerSelections[word.index] ?? word.text;
        String correctAns = _correctAnswers[word.index] ?? '';
        if (correctAns == "BOTH" || selected == correctAns) correctCount++;
      }
    }
    _finalizeCheck(correctCount, blankCount);
  }

  void _checkArticleAnswer() {
    int correct = 0, error = 0, missed = 0;
    for (var word in _currentWords) {
      String? correctArt = _correctAnswers[word.index];
      String? selectedArt = _playerSelections[word.index];
      if (correctArt != null) {
        if (selectedArt != null && selectedArt.toLowerCase() == correctArt.toLowerCase()) {
          correct++;
        } else {
          missed++;
        }
      } else {
        if (selectedArt != null) error++;
      }
    }
    _finalizeCheck(correct, correct + missed + error);
  }

  void _finalizeCheck(int correct, int total) {
    _totalCorrectBlanks += correct;
    _totalBlanks += total;
    _questionResults.add(correct == total && total > 0);
    setState(() => _isAnswerChecked = true);
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
      setState(() => _currentIndex++);
      _loadCurrentQuestion();
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    } else {
      _finishTest();
    }
  }

  Future<void> _finishTest() async {
    int score = _totalCorrectBlanks;
    int total = _totalBlanks;
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings =
        prefs.getStringList('mock_test_history') ?? [];
    historyStrings.add(json.encode({
      'timestamp': timestamp,
      'score': score,
      'total': total,
    }));
    await prefs.setStringList('mock_test_history', historyStrings);

    if (mounted) _showSummaryDialog(score, total);
  }

  void _showSummaryDialog(int score, int total) {
    final int pct = total > 0 ? ((score / total) * 100).round() : 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Test Complete! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: pct >= 80
                      ? [AppColors.greenDark, AppColors.green]
                      : pct >= 60
                          ? [const Color(0xFFD97706), AppColors.amber]
                          : [const Color(0xFFDC2626), AppColors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You got $score out of $total blanks correct.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.pop();
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Finish',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final question = widget.questions[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF13131F) : AppColors.background;
    final surfaceColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D2D3F) : AppColors.border;

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

    final totalQ = widget.questions.length;
    final liveScore = _totalBlanks > 0
        ? ((_totalCorrectBlanks / _totalBlanks) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Header
          Container(
            color: surfaceColor,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    // Quit button
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text('Quit Test?'),
                            content: const Text('Progress will not be saved.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(c);
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Quit',
                                  style: TextStyle(color: AppColors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.red.withOpacity(0.15)
                              : const Color(0xFFFEE2E2),
                          border: Border.all(
                            color: isDark
                                ? AppColors.red.withOpacity(0.3)
                                : const Color(0xFFFCA5A5),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded,
                                size: 14,
                                color: isDark ? AppColors.red : const Color(0xFF991B1B)),
                            const SizedBox(width: 4),
                            Text(
                              'Quit',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.red : const Color(0xFF991B1B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Text(
                          'Mock Test',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Question ${_currentIndex + 1} of $totalQ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Live score pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$liveScore%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Progress dots
                SizedBox(
                  height: 6,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: totalQ,
                    separatorBuilder: (_, __) => const SizedBox(width: 3),
                    itemBuilder: (ctx, i) {
                      Color dotColor;
                      if (i < _questionResults.length) {
                        dotColor = _questionResults[i]
                            ? AppColors.green
                            : AppColors.red;
                      } else if (i == _currentIndex) {
                        dotColor = AppColors.primary;
                      } else {
                        dotColor = isDark
                            ? const Color(0xFF2D2D3F)
                            : AppColors.surface2;
                      }
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _currentIndex ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dotColor,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      border: Border.all(color: borderColor, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.07),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Question ${_currentIndex + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.08,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        widget.questions[_currentIndex].type == 'article'
                            ? _buildArticleContent(
                                isDark, surfaceColor, borderColor)
                            : _buildGenericContent(
                                isDark, surfaceColor, borderColor),
                      ],
                    ),
                  ),

                  // ── Explanation
                  if (_isAnswerChecked && explanationContent.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? null
                            : const LinearGradient(
                                colors: [
                                  Color(0xFFEDE9FE),
                                  Color(0xFFDBEAFE),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: isDark ? const Color(0xFF1E1E2E) : null,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3A3A50)
                              : const Color(0xFFC4B5FD),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                'Grammar Note',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF4C1D95),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          MarkdownBody(
                            data: explanationContent,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF5B21B6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ] else
                    const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Bottom bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E2E).withOpacity(0.97)
                  : Colors.white.withOpacity(0.97),
              border: Border(top: BorderSide(color: borderColor, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: _isAnswerChecked
                  ? _gradientButton(
                      label: _currentIndex < totalQ - 1
                          ? (loc.tryGet('next_question') ?? 'Next Question')
                          : (loc.tryGet('finish') ?? 'Finish'),
                      icon: _currentIndex < totalQ - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_circle_rounded,
                      onTap: _nextQuestion,
                      color1: AppColors.greenDark,
                      color2: AppColors.green,
                    )
                  : _gradientButton(
                      label: loc.tryGet('check') ?? 'Check',
                      icon: Icons.check_circle_outline_rounded,
                      onTap: _checkAnswer,
                      color1: AppColors.primaryDark,
                      color2: const Color(0xFF7C3AED),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericContent(
      bool isDark, Color surfaceColor, Color borderColor) {
    return Wrap(
      spacing: 0,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: _currentWords.map((word) {
        if (word.isSpace) return const Text(' ', style: TextStyle(fontSize: 18));

        if (!word.isTarget) {
          return Text(
            word.text,
            style: TextStyle(
              fontSize: 18,
              height: 1.6,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          );
        }

        String displayText = _playerSelections[word.index] ?? word.text;
        bool isInteracted = _playerSelections.containsKey(word.index);

        if (_isAnswerChecked) {
          String correctAns = _correctAnswers[word.index] ?? '';
          bool isCorrect =
              correctAns == "BOTH" || displayText == correctAns;

          if (!isCorrect) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _resultChip(displayText, isCorrect: false, isDark: isDark,
                      strikethrough: true),
                  _resultChip(correctAns, isCorrect: true, isDark: isDark),
                ],
              ),
            );
          }
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: _resultChip(displayText, isCorrect: true, isDark: isDark),
          );
        }

        return GestureDetector(
          onTap: () => _handleWordClick(word.index),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isInteracted
                  ? (isDark ? AppColors.primary.withOpacity(0.2) : const Color(0xFFEEF2FF))
                  : (isDark ? const Color(0xFF2D2D3F) : AppColors.surface2),
              border: Border.all(
                color: isInteracted
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF3A3A50) : AppColors.primaryLight),
                width: isInteracted ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildArticleContent(
      bool isDark, Color surfaceColor, Color borderColor) {
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
            if (selectedArt != null) isError = true;
          }
        }

        List<Widget> children = [];
        String format(String s) =>
            word.shouldCapitalizeArticle ? _capitalize(s) : s;

        if (selectedArt != null || (isMissed && correctArt != null)) {
          String textToShow = '';
          Color color = AppColors.primary;
          TextDecoration? decoration;

          if (_isAnswerChecked) {
            if (isCorrect) {
              textToShow = selectedArt!;
              color = AppColors.green;
            } else if (isMissed) {
              if (selectedArt != null) {
                children.add(Text(
                  '$selectedArt ',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.red,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.bold,
                  ),
                ));
              }
              textToShow = format(correctArt!);
              color = AppColors.amber;
            } else if (isError) {
              textToShow = selectedArt!;
              color = AppColors.red;
              decoration = TextDecoration.lineThrough;
            }
          } else {
            textToShow = selectedArt ?? '';
          }

          if (textToShow.isNotEmpty) {
            children.add(Text(
              '$textToShow ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
                decoration: decoration,
              ),
            ));
          }
        }

        String wordDisplay = word.originalText;
        if (selectedArt != null || (isMissed && correctArt != null)) {
          if (!_namesLower.contains(word.text.toLowerCase()) &&
              wordDisplay != 'I') {
            wordDisplay = wordDisplay.toLowerCase();
          }
        }

        children.add(Text(
          wordDisplay,
          style: TextStyle(
            fontSize: 18,
            height: 1.5,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ));

        return GestureDetector(
          onTap: () => _handleWordClick(word.index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: (selectedArt != null && !_isAnswerChecked)
                  ? (isDark
                        ? AppColors.primary.withOpacity(0.15)
                        : const Color(0xFFEEF2FF))
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        );
      }).toList(),
    );
  }

  Widget _resultChip(String text,
      {required bool isCorrect,
      required bool isDark,
      bool strikethrough = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCorrect
            ? (isDark ? AppColors.green.withOpacity(0.15) : const Color(0xFFD1FAE5))
            : (isDark ? AppColors.red.withOpacity(0.15) : const Color(0xFFFEE2E2)),
        border: Border.all(
          color: isCorrect
              ? AppColors.green.withOpacity(0.5)
              : AppColors.red.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isCorrect
              ? (isDark ? AppColors.green : const Color(0xFF065F46))
              : (isDark ? AppColors.red : const Color(0xFF991B1B)),
          decoration: strikethrough ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color1,
    required Color color2,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color1, color2]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color2.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

extension LocalizationExt on AppLocalizations {
  String? tryGet(String key) {
    try {
      return get(key);
    } catch (e) {
      return null;
    }
  }
}
