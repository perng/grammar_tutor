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
import '../../../theme/app_colors.dart';

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
  final String explanationTitle;
  final String routePrefix;

  const GenericGameScreen({
    super.key,
    required this.levelIndex,
    required this.assetPath,
    this.explanationTitle = '',
    this.routePrefix = '',
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
  int _correctCount = 0;
  int _wrongCount = 0;
  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;

  StoryLevel? _story;
  int _totalLevels = 0;

  final Random _random = Random();

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
        String content = part.substring(1, part.length - 1);

        String separator = '|';
        bool allCorrect = false;

        if (content.contains('|')) {
          separator = '|';
        } else if (content.contains('~')) {
          separator = '~';
          allCorrect = true;
        } else {
          separator = '|';
        }

        List<String> forms = content.split(separator);

        if (forms.isNotEmpty) {
          String correctForm = allCorrect ? "BOTH" : forms[0];
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
    int nextOptionIndex = (currentOptionIndex + 1) % word.options.length;
    String next = word.options[nextOptionIndex];

    setState(() {
      _playerSelections[index] = next;
    });
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
      _correctCount = correct;
      _wrongCount = error;
      _showResults = true;
    });

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
      _correctCount = 0;
      _wrongCount = 0;
      if (_story != null) {
        _processText(_story!.content);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_story == null) {
      return const Scaffold(
        body: Center(child: Text("Level not found")),
      );
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

    // Count total blanks for progress bar
    final totalBlanks = _words.where((w) => w.isTarget).length;
    final answeredBlanks = _playerSelections.length;
    final bgColor = isDark ? const Color(0xFF13131F) : AppColors.background;
    final surfaceColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D2D3F) : AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Top bar with progress
              Container(
                color: surfaceColor,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _story!.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Book icon to show explanation
                        GestureDetector(
                          onTap: () {
                            ExplanationDialog.show(
                              context,
                              widget.assetPath,
                              'dummy/${widget.levelIndex}',
                            );
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2D2D3F)
                                  : AppColors.surface2,
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 16,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _showResults
                              ? 'Results'
                              : 'Tap highlighted words to change them',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (!_showResults)
                          Text(
                            '$answeredBlanks / $totalBlanks',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _showResults
                            ? _scorePercentage / 100.0
                            : (totalBlanks > 0
                                  ? answeredBlanks / totalBlanks
                                  : 0.0),
                        minHeight: 5,
                        backgroundColor: isDark
                            ? const Color(0xFF2D2D3F)
                            : AppColors.surface2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _showResults
                              ? (_scorePercentage >= 80
                                    ? AppColors.green
                                    : (_scorePercentage >= 60
                                          ? AppColors.amber
                                          : AppColors.red))
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Score badges (when results shown)
              if (_showResults)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      _scoreBadge(
                        label: 'Correct',
                        value: '$_correctCount',
                        color: AppColors.green,
                        bgColor: isDark
                            ? AppColors.green.withOpacity(0.1)
                            : const Color(0xFFF0FDF4),
                        borderColor: isDark
                            ? AppColors.green.withOpacity(0.3)
                            : const Color(0xFFA7F3D0),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _scoreBadge(
                        label: 'Wrong',
                        value: '$_wrongCount',
                        color: AppColors.red,
                        bgColor: isDark
                            ? AppColors.red.withOpacity(0.1)
                            : const Color(0xFFFEF2F2),
                        borderColor: isDark
                            ? AppColors.red.withOpacity(0.3)
                            : const Color(0xFFFCA5A5),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _scoreBadge(
                        label: 'Score',
                        value: '$_scorePercentage%',
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                        bgColor: isDark
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surface2,
                        borderColor: isDark
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.border,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

              // ── Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sentence card
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
                        child: Wrap(
                          spacing: 0,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: _words.map((word) {
                            if (word.isSpace) {
                              return const Text(
                                ' ',
                                style: TextStyle(fontSize: 18),
                              );
                            }

                            if (!word.isTarget) {
                              return Text(
                                word.text,
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 1.6,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              );
                            }

                            // ── Target word
                            String displayText =
                                _playerSelections[word.index] ?? word.text;
                            bool isInteracted =
                                _playerSelections.containsKey(word.index);

                            if (_showResults) {
                              String correctAns =
                                  _correctAnswers[word.index] ?? '';
                              bool isCorrect = correctAns == "BOTH" ||
                                  displayText == correctAns;

                              if (!isCorrect) {
                                // Show wrong → correct
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Wrap(
                                    spacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.red.withOpacity(0.15)
                                              : const Color(0xFFFEE2E2),
                                          border: Border.all(
                                            color: AppColors.red
                                                .withOpacity(0.5),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          displayText,
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: isDark
                                                ? AppColors.red
                                                : const Color(0xFF991B1B),
                                            decoration:
                                                TextDecoration.lineThrough,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.green
                                                  .withOpacity(0.15)
                                              : const Color(0xFFD1FAE5),
                                          border: Border.all(
                                            color: AppColors.green
                                                .withOpacity(0.5),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          correctAns,
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: isDark
                                                ? AppColors.green
                                                : const Color(0xFF065F46),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                // Correct
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.green.withOpacity(0.15)
                                        : const Color(0xFFD1FAE5),
                                    border: Border.all(
                                      color: AppColors.green.withOpacity(0.5),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    displayText,
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: isDark
                                          ? AppColors.green
                                          : const Color(0xFF065F46),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              }
                            }

                            // Not showing results yet — tappable blank
                            return GestureDetector(
                              onTap: () => _handleWordClick(word.index),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isInteracted
                                      ? (isDark
                                            ? AppColors.primary
                                                .withOpacity(0.2)
                                            : const Color(0xFFEEF2FF))
                                      : (isDark
                                            ? const Color(0xFF2D2D3F)
                                            : AppColors.surface2),
                                  border: Border.all(
                                    color: isInteracted
                                        ? AppColors.primary
                                        : (isDark
                                              ? const Color(0xFF3A3A50)
                                              : AppColors.primaryLight),
                                    width: isInteracted ? 2 : 1.5,
                                    style: isInteracted
                                        ? BorderStyle.solid
                                        : BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  displayText,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: isInteracted
                                        ? (isDark
                                              ? AppColors.primaryLight
                                              : AppColors.primary)
                                        : (isDark
                                              ? AppColors.primaryLight
                                              : AppColors.primary),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // ── Explanation after results
                      if (_showResults && explanationContent.isNotEmpty) ...[
                        const SizedBox(height: 16),
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
                                  const Text('💡',
                                      style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Grammar Note',
                                    style: TextStyle(
                                      fontSize: 14,
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
                                selectable: true,
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
                      ],

                      if (!_showResults) const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E2E).withOpacity(0.97)
                    : Colors.white.withOpacity(0.97),
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: _showResults
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _reset,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: borderColor, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              foregroundColor: isDark
                                  ? Colors.white70
                                  : AppColors.textPrimary,
                            ),
                            child: Text(
                              loc.get('try_again'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (widget.levelIndex < _totalLevels - 1 &&
                            widget.routePrefix.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _gradientButton(
                              label: loc.get('next_level'),
                              icon: Icons.arrow_forward_rounded,
                              onTap: () {
                                context.pushReplacement(
                                  '${widget.routePrefix}/${widget.levelIndex + 1}',
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    )
                  : _gradientButton(
                      label: loc.get('check_answers'),
                      icon: Icons.check_circle_outline_rounded,
                      onTap: _checkAnswers,
                    ),
            ),
          ),

          // ── Confetti
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

  Widget _scoreBadge({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06,
                color: isDark ? Colors.white38 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF7C3AED)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
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
}
