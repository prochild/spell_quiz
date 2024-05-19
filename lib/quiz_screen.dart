import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'local_storage.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

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
    "run", "happy", "quickly", "apple", "blue", "beautiful", "jump", "elephant", "slowly",
    "strong", "computer", "read", "smart", "sky", "dog", "swim", "angry", "fast", "banana",
    "tall", "car", "laugh", "tiny", "moon", "yellow", "write", "intelligent", "grass",
    "sing", "book", "smile", "brilliant", "mouse", "green", "climb", "soft", "sun",
    "play", "clever", "tree", "walk", "red", "dolphin", "quick", "rain", "sad",
    "ocean", "watch", "happy", "jump", "run", "blue"
  ];
  final Set<int> _wrongSelections = {}; // 잘못된 선택을 저장하는 Set

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
    _initializeTts();
    debugPrint("Words loaded: $_words");
    _stopwatch.start();
    _setOptions();
    _speakWord(3);  // 초기 3번 단어 읽기
  }

  Future<void> _initializeTts() async {
    var available = await _flutterTts.isLanguageAvailable("en-US");
    if (available) {
      await _flutterTts.setLanguage("en-US");  // TTS 출력 언어 설정
      await _flutterTts.setSpeechRate(0.3); // TTS 속도 설정 (0.0 ~ 1.0)
      await _flutterTts.awaitSpeakCompletion(true); // 대기 설정
    } else {
      _showTtsInstallDialog();
    }
  }

  void _showTtsInstallDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("TTS 엔진이 필요합니다"),
          content: const Text("TTS 엔진이 설치되어 있지 않습니다. 설치하시겠습니까?"),
          actions: [
            TextButton(
              child: const Text("취소"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("설치"),
              onPressed: () {
                Navigator.of(context).pop();
                _launchTtsInstall();
              },
            ),
          ],
        );
      },
    );
  }

  void _launchTtsInstall() async {
    const url = 'https://play.google.com/store/apps/details?id=com.google.android.tts';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _setOptions() {
    debugPrint("Setting options for current word index: $_currentWordIndex");
    setState(() {
      _wrongSelections.clear(); // 새로운 문제를 시작할 때 잘못된 선택 초기화
      _options = [_words[_currentWordIndex]];
      List<String> allWords = List.from(_randomWords)..addAll(_words);
      allWords = allWords.toSet().toList();  // 중복 제거
      allWords.remove(_words[_currentWordIndex]); // 문제 단어 제거
      while (_options.length < 4) {
        String randomWord = allWords[Random().nextInt(allWords.length)];
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
      try {
        await _flutterTts.speak(_words[_currentWordIndex]);
        await Future.delayed(const Duration(seconds: 1)); // 말하는 시간 간격을 두기 위해 대기
      } catch (e) {
        debugPrint("TTS error: $e");
      }
    }
  }

  void _checkAnswer(String selectedWord, int index) {
    debugPrint("Selected word: $selectedWord, correct word: ${_words[_currentWordIndex]}");
    if (!mounted) return; // 상태 객체가 트리에 없는 경우 return
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
        try {
          Vibration.vibrate(duration: 500); // 진동 추가
        } catch (e) {
          debugPrint("Vibration error: $e");
        }
        _wrongSelections.add(index); // 잘못된 선택을 기록
      }
    });
  }

  void _showResults() {
    debugPrint("Showing results: attempts = $_attempts, elapsed time = ${_stopwatch.elapsed}");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          attempts: _attempts,
          elapsedTime: _stopwatch.elapsed,
          onRestart: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const QuizScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _flutterTts.stop();
    super.dispose();
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
            ..._options.asMap().entries.map((entry) {
              int index = entry.key;
              String word = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: ElevatedButton(
                  onPressed: _wrongSelections.contains(index)
                      ? null
                      : () => _checkAnswer(word, index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wrongSelections.contains(index) ? Colors.red : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        word,
                        style: const TextStyle(fontSize: 24), // 글자 크기 조정
                      ),
                      if (_wrongSelections.contains(index))
                        const Icon(Icons.clear, color: Colors.white),
                    ],
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
  final VoidCallback onRestart;

  const ResultsScreen({super.key, 
    required this.attempts,
    required this.elapsedTime,
    required this.onRestart,
  });

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
            const Text(
              '게임 종료!',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              '걸린 시간: ${elapsedTime.inSeconds}초',
              style: const TextStyle(fontSize: 24),
            ),
            Text(
              '시도 횟수: $attempts',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text('다시 풀기'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text('처음 화면으로'),
            ),
          ],
        ),
      ),
    );
  }
}