import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/vocab_hero_models.dart';

class VocabHeroGameScreen extends StatefulWidget {
  final String levelId;

  const VocabHeroGameScreen({super.key, required this.levelId});

  @override
  State<VocabHeroGameScreen> createState() => _VocabHeroGameScreenState();
}

class _VocabHeroGameScreenState extends State<VocabHeroGameScreen> {
  List<VocabQuestion> _questions = [];
  int _currentIndex = 0;

  List<String> _currentOptions = [];
  String? _selectedOption;
  bool _isProcessing = false;
  bool _showContinue = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/VocabHero/${widget.levelId}.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      final questions = jsonData.map((e) => VocabQuestion.fromJson(e)).toList();

      // Load scores
      final prefs = await SharedPreferences.getInstance();
      for (var q in questions) {
        final key = 'vocabHero-${q.id}';
        final score = prefs.getString(key);
        q.score = score != null ? (double.tryParse(score)?.toInt() ?? 0) : 0;
      }

      // Sort logic similar to React (low score first, random shuffle first)
      questions.shuffle();
      questions.sort((a, b) => a.score.compareTo(b.score));

      setState(() {
        _questions = questions;
        _currentIndex = 0;
      });
      _updateOptions();
    } catch (e) {
      debugPrint('Error loading questions: $e');
    }
  }

  void _updateOptions() {
    if (_questions.isEmpty) return;

    final currentQ = _questions[_currentIndex];
    final options = [currentQ.answer, ...currentQ.others];
    options.shuffle();

    setState(() {
      _currentOptions = options;
      _selectedOption = null;
      _showContinue = false;
    });
  }

  Future<void> _handleChoice(String choice) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _selectedOption = choice;
    });

    final currentQ = _questions[_currentIndex];
    final isCorrect = choice == currentQ.answer;

    final prefs = await SharedPreferences.getInstance();

    if (isCorrect) {
      // Logic for correct
      // Update score
      final newScore = currentQ.score + 1;
      currentQ.score = newScore;
      await prefs.setString('vocabHero-${currentQ.id}', newScore.toString());

      _updateLevelProgress(prefs);

      // Play audio
      await Future.delayed(const Duration(milliseconds: 500));
      await _playAudio(currentQ.answer);

      setState(() {
        _isProcessing = false;
        _showContinue =
            true; // Wait for user to continue or auto continue logic
        // React version has a timer 5s
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _showContinue) {
          _advance();
        }
      });
    } else {
      // Logic for wrong
      // Update score
      // Note: React version sets -1, flutter version sets to 0 or something?
      // React: Math.max(-1, currentScore + 1) NO wait.
      // logic: const newScore = Math.max(-1, currentScore + 1); on correct? oh correct adds 1.

      // If wrong? The react code provided didn't explicitly show "wrong" logic block separately but `isAnswerCorrect`.
      // Actually `handleChoice` handles both. If NOT correct, it just plays audio? No score update shown in else?
      // Wait, in React code:
      /*
          if (isAnswerCorrect) {
            ... update score ...
          }
          // Play audio and wait (ALWAYS)
          await new Promise(resolve => setTimeout(resolve, 500));
          ...
      */
      // So wrong answers also play audio?

      await Future.delayed(const Duration(milliseconds: 500));
      await _playAudio(currentQ.answer); // Reveal answer audio even if wrong?

      setState(() {
        _isProcessing = false;
        _showContinue = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showContinue) {
          _advance();
        }
      });
    }
  }

  Future<void> _playAudio(String word) async {
    try {
      await _audioPlayer.stop();
      final path = 'voices/english/${word.replaceAll(' ', '_')}.mp3';
      await _audioPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  Future<void> _updateLevelProgress(SharedPreferences prefs) async {
    int mastered = _questions
        .where((q) => q.score >= 1)
        .length; // assuming 1 is mastery thresh
    double progress = _questions.isNotEmpty
        ? (mastered / _questions.length) * 100
        : 0.0;
    await prefs.setString(
      'vocabHero-progress-${widget.levelId}',
      progress.toString(),
    );
  }

  void _advance() {
    setState(() {
      _isProcessing = false;
      _currentIndex = (_currentIndex + 1) % _questions.length;

      // Resort logic every batch? Skipping complex sorting for now
    });
    _updateOptions();
  }

  String _getSentenceHtml(VocabQuestion question) {
    if (_selectedOption != null) {
      // Replace blank
      return question.sentence.replaceAll(
        "______",
        "**${question.answer} (${question.wordTranslationZhTw})**",
      );
    }
    return question.sentence;
  }

  String _getOptionTranslation(String option, VocabQuestion question) {
    if (option == question.answer) {
      return question.wordTranslationZhTw;
    }
    final index = question.others.indexOf(option);
    if (index != -1 && index < question.othersZhTw.length) {
      return question.othersZhTw[index];
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQ = _questions[_currentIndex];

    // Progress
    final mastered = _questions.where((q) => q.score >= 1).length;
    final progress = _questions.isNotEmpty
        ? (mastered / _questions.length)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Vocab Level ${widget.levelId.split('_').last}'),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sentence
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        MarkdownBody(
                          data: _getSentenceHtml(currentQ),
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 20,
                              height: 1.5,
                              color: Colors.blueGrey,
                            ),
                            strong: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_selectedOption != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            currentQ.sentenceZhTw,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Options
                  ..._currentOptions.map((option) {
                    Color color = Colors.white;
                    Color borderColor = Colors.grey.shade300;

                    bool isAnswer = (option == currentQ.answer);
                    bool isSelected = (option == _selectedOption);

                    if (_selectedOption != null) {
                      if (isAnswer) {
                        color = Colors.green.shade100;
                        borderColor = Colors.green;
                      } else if (isSelected) {
                        color = Colors.red.shade100;
                        borderColor = Colors.red;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        onPressed: (_isProcessing || _showContinue)
                            ? null
                            : () => _handleChoice(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor:
                              color, // Keep validation colors even when disabled
                          disabledForegroundColor: Colors.black87,
                        ),
                        child: Column(
                          children: [
                            Text(option, style: const TextStyle(fontSize: 18)),
                            if (_selectedOption != null)
                              Text(
                                "(${_getOptionTranslation(option, currentQ)})",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (_showContinue)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: ElevatedButton(
                        onPressed: _advance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
