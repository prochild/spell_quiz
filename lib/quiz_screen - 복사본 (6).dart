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
  final List<String> _randomWords = [
    "orange", "grape", "lemon", "peach", "plum", "kiwi", "berry", "melon", "mango", "papaya"
  ];

  @override
  void initState() {
    super.initState();
    debugPrint("QuizScreen initState called");
    _words = LocalStorage.getWords();
    if (_words.isEmpty) {
      debugPrint("No words found, returning to previous screen");
      Navigator.pop(context);
      return;
    }
    _flutterTts.setLanguage("en-US");  // TTS 출력 언어 설정
    _flutterTts.setSpeechRate(0.5); // TTS 속도 설정 (0.0 ~ 1.0)
    debugPrint("Words loaded: $_words");
    _stopwatch.start();
    _setOptions();
    _speakWord(3);  // 초기 3번 단어 읽기
  }

  void _setOptions() {
    debugPrint("Setting options for current word index: $_currentWordIndex");
    setState(() {
      _options = [_words[_currentWordIndex]];
      while (_options.length < 4) {
        String randomWord = _randomWords[Random().nextInt(_randomWords.length)];
        if (!_options.contains(randomWord)) {
          _options.add(randomWord);
        }
      }
      _options.shuffle();
      debugPrint("Options set: $_options");
    });
  }

  void _speakWord(int times) async {
    debugPrint("Speaking word: ${_words[_currentWordIndex]} $times times");
    for (int i = 0; i < times; i++) {
      await _flutterTts.speak(_words[_currentWordIndex]);
    }
  }

  void _checkAnswer(String selectedWord) {
    debugPrint("Selected word: $selectedWord, correct word: ${_words[_currentWordIndex]}");
    setState(() {
      _attempts++;
      if (selectedWord == _words[_currentWordIndex]) {
        debugPrint("Correct answer");
        if (_currentWordIndex < _words.length - 1) {
          _currentWordIndex++;
          _setOptions();
          _speakWord(3);  // 다음 단어도 3번 읽기
        } else {
          debugPrint("All words completed");
          _stopwatch.stop();
          _showResults();
        }
      } else {
        debugPrint("Incorrect answer");
      }
    });
  }

  void _showResults() {
    debugPrint("Showing results: attempts = $_attempts, elapsed time = ${_stopwatch.elapsed}");
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
    debugPrint("Building QuizScreen with options: $_options");
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 맞추기'),
      ),
      body: _options.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(
              value: (_currentWordIndex + 1) / _words.length,
              backgroundColor: Colors.grey,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              '${_currentWordIndex + 1} / ${_words.length}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _speakWord(1),
              child: const Text('다시 듣기'),
            ),
            const SizedBox(height: 20),
            ..._options.map((word) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: ElevatedButton(
                  onPressed: () => _checkAnswer(word),
                  child: Text(
                    word,
                    style: const TextStyle(fontSize: 24), // 글자 크기 조정
                  ),
                ),
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
    debugPrint("Building ResultsScreen");
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
