import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'local_storage.dart';
import 'dart:math';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  List<String> _words = [];
  int _currentWordIndex = 0;
  int _attempts = 0;
  final Stopwatch _stopwatch = Stopwatch();
  List<String> _options = [];

  @override
  void initState() {
    super.initState();
    _words = LocalStorage.getWords();
    _stopwatch.start();
    _setOptions();
  }

  void _setOptions() {
    _options = [_words[_currentWordIndex]];
    while (_options.length < 4) {
      String randomWord = _words[Random().nextInt(_words.length)];
      if (!_options.contains(randomWord)) {
        _options.add(randomWord);
      }
    }
    _options.shuffle();
  }

  void _speakWord() async {
    for (int i = 0; i < 3; i++) {
      await _flutterTts.speak(_words[_currentWordIndex]);
    }
  }

  void _checkAnswer(String selectedWord) {
    setState(() {
      _attempts++;
      if (selectedWord == _words[_currentWordIndex]) {
        if (_currentWordIndex < _words.length - 1) {
          _currentWordIndex++;
          _setOptions();
        } else {
          _stopwatch.stop();
          _showResults();
        }
      }
    });
  }

  void _showResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          attempts: _attempts,
          elapsedTime: _stopwatch.elapsed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 맞추기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _speakWord,
              child: const Text('다시 듣기'),
            ),
            ..._options.map((word) {
              return ElevatedButton(
                onPressed: () => _checkAnswer(word),
                child: Text(word),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class ResultsScreen extends StatelessWidget {
  final int attempts;
  final Duration elapsedTime;

  const ResultsScreen({super.key, required this.attempts, required this.elapsedTime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결과 화면'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('걸린 시간: ${elapsedTime.inSeconds}초'),
            Text('시도 횟수: $attempts'),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('처음 화면으로'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('프로그램 종료'),
            ),
          ],
        ),
      ),
    );
  }
}
