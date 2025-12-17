import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/word_flash_models.dart';

class WordFlashGameScreen extends StatefulWidget {
  final String levelId;
  final String gameType;

  const WordFlashGameScreen({
    super.key,
    required this.levelId,
    this.gameType = 'wordflash',
  });

  @override
  State<WordFlashGameScreen> createState() => _WordFlashGameScreenState();
}

class _WordFlashGameScreenState extends State<WordFlashGameScreen> {
  List<WordWithScore> _wordList = [];
  int _currentIndex = 0;
  List<String> _choices = [];
  String? _selectedChoice;
  bool _isProcessing = false;
  // bool _hasUserInteracted = false;
  bool _fastMode = false;
  bool _showExamples = false;
  bool _blindMode = false;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadLevelData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fastMode = prefs.getString('${widget.gameType}_fastMode') == 'true';
      _showExamples =
          prefs.getString('${widget.gameType}_showExamples') == 'true';
      _blindMode = prefs.getString('${widget.gameType}_blindMode') == 'true';
    });
  }

  Future<void> _loadLevelData() async {
    try {
      // Load words from JSON
      final String jsonString = await rootBundle.loadString(
        'assets/data/${widget.gameType}/${widget.levelId}.json',
      );
      final List<dynamic> jsonData = json.decode(
        jsonString,
      ); // It's an array of WordData

      final rawWords = jsonData.map((e) => WordData.fromJson(e)).toList();

      // Flatten
      final prefs = await SharedPreferences.getInstance();
      List<WordWithScore> preparedList = [];

      for (var word in rawWords) {
        for (var meaning in word.meanings) {
          final key = '${widget.gameType}-${word.word}-${meaning.meaningIndex}';
          final scoreStr = prefs.getString(key);
          final score = (scoreStr != null)
              ? (double.tryParse(scoreStr)?.toInt() ?? 0)
              : 0;

          preparedList.add(
            WordWithScore(word: word.word, meaning: meaning, score: score),
          );
        }
      }

      _sortWordList(preparedList);

      setState(() {
        _wordList = preparedList;
        _currentIndex = 0;
      });
      _updateChoices();

      // Auto play first word? Usually wait for interaction or simple start
      // _playCurrentWord();
    } catch (e) {
      debugPrint('Error loading level data: $e');
    }
  }

  void _sortWordList(List<WordWithScore> list) {
    list.sort((a, b) {
      if (a.word == b.word) return (Random().nextDouble() - 0.5).toInt();
      return a.score.compareTo(b.score);
    });
  }

  void _updateChoices() {
    if (_wordList.isEmpty) return;

    final currentWord = _wordList[_currentIndex];
    final allChoices = [
      currentWord.meaning.meaningZhTw,
      ...currentWord.meaning.wrongMeaningZhTw,
    ];
    allChoices.shuffle();
    setState(() {
      _choices = allChoices;
      _selectedChoice = null;
    });
  }

  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.stop();
      // 'voices/english/...' is in assets/voices/english/...
      // AudioPlayer expects asset key without 'assets/' prefix if using AssetSource?
      // AssetSource adds 'assets/' prefix by default.
      // So if path is 'voices/english/hello.mp3', AssetSource('voices/english/hello.mp3') looks for 'assets/voices/english/hello.mp3'.
      await _audioPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint('Error playing audio $path: $e');
    }
  }

  Future<void> _playCurrentWord() async {
    if (_wordList.isEmpty) return;
    final word = _wordList[_currentIndex].word.replaceAll(' ', '_');
    await _playAudio('voices/english/$word.mp3');
  }

  Future<void> _playDefinition() async {
    if (_wordList.isEmpty) return;
    final definition = _wordList[_currentIndex].meaning.meaningZhTw;
    final encoded = base64.encode(utf8.encode(definition));
    await _playAudio('voices/chinese/$encoded.mp3');
  }

  Future<void> _handleChoice(String choice) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _selectedChoice = choice;
    });

    final currentWord = _wordList[_currentIndex];
    final isCorrect = choice == currentWord.meaning.meaningZhTw;

    if (isCorrect) {
      // Correct Logic
      if (!_fastMode) {
        // Play definition provided logic
        // await _playDefinition(); // Maybe skip for now as Chinese TTS files might be missing or large
        // If files are there:
        await _playDefinition();
        await Future.delayed(const Duration(milliseconds: 700));
        await _playCurrentWord();
      }

      // Update score
      final prefs = await SharedPreferences.getInstance();
      final key =
          '${widget.gameType}-${currentWord.word}-${currentWord.meaning.meaningIndex}';

      final currentScore = currentWord.score;
      final newScore = currentScore + 1;

      await prefs.setString(key, newScore.toString());

      // Update local state
      setState(() {
        currentWord.score = newScore;
      });

      // Recalculate progress for this level
      _updateLevelProgress(prefs);

      await Future.delayed(const Duration(milliseconds: 1000));

      if (_showExamples) {
        // Show example popup TODO
        _advanceToNext();
      } else {
        _advanceToNext();
      }
    } else {
      // Wrong Logic
      await Future.delayed(const Duration(milliseconds: 1000));
      _advanceToNext();
    }
  }

  Future<void> _updateLevelProgress(SharedPreferences prefs) async {
    // Count mastered
    final masteredCount = _wordList.where((w) => w.score >= 1).length;
    final total = _wordList.length;
    final progress = total > 0 ? (masteredCount / total) * 100 : 0.0;

    await prefs.setString(
      '${widget.gameType}-progress-${widget.levelId}',
      progress.toString(),
    );
  }

  void _advanceToNext() {
    setState(() {
      _isProcessing = false;
      _currentIndex = (_currentIndex + 1) % _wordList.length;

      // If we cycled, maybe Resort?
      if (_currentIndex == 0) {
        _sortWordList(_wordList);
      }
    });
    _updateChoices();
    // Play next word?
    if (!_isProcessing) {
      // Only if not blocked
      _playCurrentWord();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_wordList.isEmpty)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentWord = _wordList[_currentIndex];

    // Progress calculation for UI
    final total = _wordList.length;
    final mastered = _wordList.where((w) => w.score >= 1).length;
    final progress = (total > 0) ? (mastered / total) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gameType} ${widget.levelId.split('_').last}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Show settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Word Display
                      GestureDetector(
                        onTap: _playCurrentWord,
                        child: Text(
                          (_blindMode && _selectedChoice == null)
                              ? '?' * currentWord.word.length
                              : currentWord.word,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentWord.meaning.type,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 32),
                        onPressed: _playCurrentWord,
                      ),
                      const SizedBox(height: 40),
                      // Choices
                      ..._choices.map((choice) {
                        final isSelected = _selectedChoice == choice;
                        // final isCorrect = choice == currentWord.meaning.meaningZhTw; // Unused in this scope, used in _handleChoice logic

                        Color color = Colors.white;
                        Color borderColor = Colors.grey.shade300;

                        if (_selectedChoice != null) {
                          if (choice == currentWord.meaning.meaningZhTw) {
                            color = Colors.green.shade100;
                            borderColor = Colors.green;
                          } else if (isSelected) {
                            color = Colors.red.shade100;
                            borderColor = Colors.red;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _handleChoice(choice),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: borderColor),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                choice,
                                style: const TextStyle(fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
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
