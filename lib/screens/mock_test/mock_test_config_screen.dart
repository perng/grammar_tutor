import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/story_level.dart';
import '../../theme/app_colors.dart';

class MockTestConfigScreen extends StatefulWidget {
  const MockTestConfigScreen({super.key});

  @override
  State<MockTestConfigScreen> createState() => _MockTestConfigScreenState();
}

class _MockTestConfigScreenState extends State<MockTestConfigScreen> {
  double _questionCount = 20;
  bool _isLoading = false;
  List<Map<String, dynamic>> _history = [];

  static const List<String> _dataFiles = [
    'adjective_order.json', 'adjectives.json', 'adverbs.json',
    'an_a_the.json', 'articles.json', 'be_verb_adjectives.json',
    'comparisons.json', 'conditionals.json', 'conjunctions.json',
    'construction_patterns.json', 'countable_uncountable.json',
    'determiners.json', 'future_tenses.json', 'gerunds_infinitives.json',
    'imperative_mood.json', 'modals.json', 'negatives.json',
    'other_pronouns.json', 'passive_voice.json', 'past_tenses.json',
    'phrasal_verbs.json', 'possessive_nouns.json', 'prepositions.json',
    'present_continuous.json', 'present_perfect.json', 'pronouns.json',
    'question_formation.json', 'relative_clauses.json', 'singular.json',
    'subjunctive_mood.json', 'tag_questions.json', 'transitive_intransitive.json',
    'verbs.json',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings =
        prefs.getStringList('mock_test_history') ?? [];

    setState(() {
      _history = historyStrings
          .map((s) => json.decode(s) as Map<String, dynamic>)
          .toList();
      _history.sort(
        (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
      );
      if (_history.length > 20) {
        _history = _history.sublist(0, 20);
      }
    });
  }

  Future<void> _startTest() async {
    setState(() => _isLoading = true);

    try {
      List<StoryLevel> allQuestions = [];
      List<String> shuffledFiles = List.from(_dataFiles)..shuffle();

      for (String fileName in shuffledFiles) {
        try {
          final String response =
              await rootBundle.loadString('assets/data/$fileName');
          final List<dynamic> data = json.decode(response);
          for (var item in data) {
            if (fileName == 'an_a_the.json' || fileName == 'articles.json') {
              item['type'] = 'article';
            } else {
              item['type'] = 'generic';
            }
            allQuestions.add(StoryLevel.fromJson(item));
          }
        } catch (e) {
          debugPrint('Error loading $fileName: $e');
        }
      }

      allQuestions.shuffle();
      final selectedQuestions =
          allQuestions.take(_questionCount.toInt()).toList();

      if (selectedQuestions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load questions.')),
          );
        }
        return;
      }

      if (mounted) {
        GoRouter.of(context)
            .push('/mock-test/runner', extra: selectedQuestions)
            .then((_) => _loadHistory());
      }
    } catch (e) {
      debugPrint('Error starting test: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF13131F) : AppColors.background;
    final surfaceColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D2D3F) : AppColors.border;

    final int estMinutes = (_questionCount / 1.7).round();

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // ── Header card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -10,
                  child: Text(
                    '📝',
                    style: TextStyle(
                      fontSize: 72,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRACTICE MODE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.mockTestTitle,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Randomised questions from all grammar categories',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Question count
          _card(
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            title: '🔢  Number of Questions',
            child: Column(
              children: [
                Text(
                  '${_questionCount.round()}',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                Text(
                  'questions',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 18),
                  ),
                  child: Slider(
                    value: _questionCount,
                    min: 10,
                    max: 50,
                    divisions: 4,
                    label: _questionCount.round().toString(),
                    onChanged: (v) => setState(() => _questionCount = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '10 (quick)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '50 (full)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surface2,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Estimated time: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '~$estMinutes minutes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Start button
          GestureDetector(
            onTap: _startTest,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF7C3AED)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.38),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '${loc.startTest}  ·  ${_questionCount.round()} Questions',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── History
          Row(
            children: [
              Text(
                'RECENT TESTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                  color: isDark ? Colors.white38 : AppColors.textMuted,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),

          if (_history.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border.all(color: borderColor, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  loc.noTestsYet,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ...List.generate(_history.length, (index) {
              final item = _history[index];
              final date = DateTime.fromMillisecondsSinceEpoch(
                item['timestamp'] as int,
              );
              final score = item['score'] as int;
              final total = item['total'] as int;
              final pct = total > 0 ? ((score / total) * 100).round() : 0;

              Color ringColor;
              String badge;
              if (pct >= 80) {
                ringColor = AppColors.green;
                badge = 'Great';
              } else if (pct >= 60) {
                ringColor = AppColors.amber;
                badge = 'Good';
              } else {
                ringColor = AppColors.red;
                badge = 'Try again';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border.all(color: borderColor, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // Score ring
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ringColor, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: ringColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat.yMMMd().add_jm().format(date),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$score / $total correct',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? ringColor.withOpacity(0.15)
                              : ringColor.withOpacity(0.1),
                          border: Border.all(
                              color: ringColor.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: ringColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _card({
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
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
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.08,
                  color: isDark ? Colors.white38 : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
