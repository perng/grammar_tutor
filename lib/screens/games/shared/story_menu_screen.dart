import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/story_level.dart';

class StoryMenuScreen extends StatefulWidget {
  final String title;
  final String assetPath;
  final String routePrefix;
  final String progressKeyPrefix;

  const StoryMenuScreen({
    super.key,
    required this.title,
    required this.assetPath,
    required this.routePrefix,
    required this.progressKeyPrefix,
  });

  @override
  State<StoryMenuScreen> createState() => _StoryMenuScreenState();
}

class _StoryMenuScreenState extends State<StoryMenuScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    try {
      final String response = await rootBundle.loadString(widget.assetPath);
      final List<dynamic> data = json.decode(response);
      final levels = data.map((json) => StoryLevel.fromJson(json)).toList();

      final prefs = await SharedPreferences.getInstance();
      final Map<String, double> progress = {};

      for (int i = 0; i < levels.length; i++) {
        final String key = '${widget.progressKeyPrefix}-$i';
        final String? val = prefs.getString(key);
        double valDouble = val != null ? (double.tryParse(val) ?? 0.0) : 0.0;
        progress[i.toString()] = valDouble;
      }

      // Find first unfinished level
      int targetIndex = 0;
      for (int i = 0; i < levels.length; i++) {
        if ((progress[i.toString()] ?? 0.0) < 100) {
          targetIndex = i;
          break;
        }
      }

      if (!mounted) return;

      // Navigate immediately
      context.replace('${widget.routePrefix}/$targetIndex');
    } catch (e) {
      debugPrint('Error loading levels: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If we are here, it means there was an error loading levels (otherwise we would have redirected)
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: const Center(
        child: Text('Error loading game content. Please try again.'),
      ),
    );
  }
}
