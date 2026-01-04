import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/story_level.dart';

class MockTestConfigScreen extends StatefulWidget {
  const MockTestConfigScreen({super.key});

  @override
  State<MockTestConfigScreen> createState() => _MockTestConfigScreenState();
}

class _MockTestConfigScreenState extends State<MockTestConfigScreen> {
  double _questionCount = 10;
  bool _isLoading = false;
  List<Map<String, dynamic>> _history = [];

  static const List<String> _dataFiles = [
    'adjective_order.json',
    'adjectives.json',
    'adverbs.json',
    'an_a_the.json',
    'articles.json',
    'be_verb_adjectives.json',
    'comparisons.json',
    'conditionals.json',
    'conjunctions.json',
    'construction_patterns.json',
    'countable_uncountable.json',
    'determiners.json',
    'future_tenses.json',
    'gerunds_infinitives.json',
    'imperative_mood.json',
    'modals.json',
    'negatives.json',
    'other_pronouns.json',
    'passive_voice.json',
    'past_tenses.json',
    'phrasal_verbs.json',
    'possessive_nouns.json',
    'prepositions.json',
    'present_continuous.json',
    'present_perfect.json',
    'pronouns.json',
    'question_formation.json',
    'relative_clauses.json',
    'singular.json',
    'subjunctive_mood.json',
    'tag_questions.json',
    'transitive_intransitive.json',
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
      // Sort by timestamp descending
      _history.sort(
        (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
      );
      // Keep only last 20
      if (_history.length > 20) {
        _history = _history.sublist(0, 20);
      }
    });
  }

  Future<void> _startTest() async {
    setState(() => _isLoading = true);

    try {
      // 1. Load all questions
      List<StoryLevel> allQuestions = [];

      // Shuffle file list to ensure randomness if we were to stop early (though we won't here)
      List<String> shuffledFiles = List.from(_dataFiles)..shuffle();

      for (String fileName in shuffledFiles) {
        try {
          final String response = await rootBundle.loadString(
            'assets/data/$fileName',
          );
          final List<dynamic> data = json.decode(response);
          for (var item in data) {
            // Create StoryLevel objects, adding source file for context if needed
            // (StoryLevel doesn't current store source, but that's fine)
            allQuestions.add(StoryLevel.fromJson(item));
          }
        } catch (e) {
          debugPrint('Error loading $fileName: $e');
        }
      }

      // 2. Select random questions
      allQuestions.shuffle();
      List<StoryLevel> selectedQuestions = allQuestions
          .take(_questionCount.toInt())
          .toList();

      if (selectedQuestions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load questions.')),
          );
        }
        return;
      }

      // 3. Navigate to runner
      // 3. Navigate to runner via GoRouter
      if (mounted) {
        GoRouter.of(
          context,
        ).push('/mock-test/runner', extra: selectedQuestions).then((_) {
          _loadHistory();
        });
      }
    } catch (e) {
      debugPrint('Error starting test: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.mockTestTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Configuration Section
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Test Configuration',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Number of Questions: ${_questionCount.round()}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Slider(
                          value: _questionCount,
                          min: 10,
                          max: 50,
                          divisions: 4,
                          label: _questionCount.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              _questionCount = value;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _startTest,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text(
                              'Start Test',
                              style: TextStyle(fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Past Results (Last 20)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (_history.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text("No tests taken yet.")),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        item['timestamp'],
                      );
                      final score = item['score'];
                      final total = item['total'];
                      final percentage = ((score / total) * 100).round();

                      Color scoreColor = Colors.red;
                      if (percentage >= 80)
                        scoreColor = Colors.green;
                      else if (percentage >= 60)
                        scoreColor = Colors.orange;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scoreColor.withOpacity(0.2),
                            child: Text(
                              '$percentage%',
                              style: TextStyle(
                                color: scoreColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          title: Text(DateFormat.yMMMd().add_jm().format(date)),
                          subtitle: Text('$score / $total correct'),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}
