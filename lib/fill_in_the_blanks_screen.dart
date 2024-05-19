import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'local_storage.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

class FillInTheBlanksScreen extends StatefulWidget {
  @override
  _FillInTheBlanksScreenState createState() => _FillInTheBlanksScreenState();
}

class _FillInTheBlanksScreenState extends State<FillInTheBlanksScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  List<String> _words = [];
  int _currentWordIndex = 0;
  int _attempts = 0;
  Stopwatch _stopwatch = Stopwatch();
  int _totalElapsedTime = 0; // 전체 실행 시간 합산
  Set<int> _wrongSelections = {}; // 잘못된 선택을 저장하는 Set
  String _currentWord = "";
  List<String> _displayWord = [];
  Map<int, List<String>> _choices = {};
  int _difficulty = 1; // 난이도 설정
  bool _isDialogShown = false; // 다이얼로그가 표시되었는지 확인하는 플래그
  bool _isDialogOpen = false; // 다이얼로그가 열려 있는지 확인하는 플래그

  final List<String> _randomConsonants = "bcdfghjklmnpqrstvwxyz".split('');
  final List<String> _randomVowels = "aeiou".split('');

  @override
  void initState() {
    super.initState();
    debugPrint("FillInTheBlanksScreen initState called");
    _words = LocalStorage.getWords();
    if (_words.isEmpty) {
      debugPrint("No words found, returning to previous screen");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return;
    }
    _initializeTts();
    debugPrint("Words loaded: $_words");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDifficultyDialog();
      });
      _isDialogShown = true;
    }
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
          title: Text("TTS 엔진이 필요합니다"),
          content: Text("TTS 엔진이 설치되어 있지 않습니다. 설치하시겠습니까?"),
          actions: [
            TextButton(
              child: Text("취소"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("설치"),
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

  void _showDifficultyDialog() {
    setState(() {
      _isDialogOpen = true;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("난이도 선택"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("쉬움"),
                onTap: () {
                  _setDifficulty(1);
                },
              ),
              ListTile(
                title: Text("보통"),
                onTap: () {
                  _setDifficulty(2);
                },
              ),
              ListTile(
                title: Text("어려움"),
                onTap: () {
                  _setDifficulty(3);
                },
              ),
            ],
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isDialogOpen = false;
      });
    });
  }

  void _setDifficulty(int difficulty) {
    setState(() {
      _difficulty = difficulty;
      Navigator.of(context).pop();
      _stopwatch.start();
      _setWord();
      _speakWord(3);  // 초기 3번 단어 읽기
    });
  }

  void _setWord() {
    debugPrint("Setting word for current word index: $_currentWordIndex");
    setState(() {
      _currentWord = _words[_currentWordIndex];
      _displayWord = List<String>.filled(_currentWord.length, "_");
      _choices.clear();
      _wrongSelections.clear(); // 잘못된 선택 초기화
      bool hasBlank = false;
      for (int i = 0; i < _currentWord.length; i++) {
        if (_currentWord[i].toUpperCase() == _currentWord[i]) { // 대문자 처리
          _displayWord[i] = _currentWord[i];
        } else if (Random().nextDouble() < _getBlankRatio() || !hasBlank) {
          _choices[i] = _generateChoices(_currentWord[i]);
          hasBlank = true;
        } else {
          _displayWord[i] = _currentWord[i];
        }
      }
    });
  }

  double _getBlankRatio() {
    switch (_difficulty) {
      case 1:
        return 0.3;
      case 2:
        return 0.5;
      case 3:
        return 0.7;
      default:
        return 0.5;
    }
  }

  List<String> _generateChoices(String correctLetter) {
    List<String> choices = [correctLetter];
    List<String> sourceList = _randomConsonants.contains(correctLetter.toLowerCase())
        ? _randomConsonants
        : _randomVowels;
    while (choices.length < 4) {
      String randomLetter = sourceList[Random().nextInt(sourceList.length)];
      if (!choices.contains(randomLetter)) {
        choices.add(randomLetter);
      }
    }
    choices.shuffle();
    return choices;
  }

  void _speakWord(int repetitions) async {
    for (int i = 0; i < repetitions; i++) {
      await _flutterTts.speak(_currentWord);
      await Future.delayed(Duration(seconds: 1));
    }
  }

  void _onLetterSelected(int index, String letter) {
    if (_isDialogOpen) return; // 다이얼로그가 열려 있을 때 입력을 무시

    setState(() {
      _attempts++;
      if (_currentWord[index].toLowerCase() == letter.toLowerCase()) {
        _displayWord[index] = _currentWord[index];
        _choices.remove(index);
        _wrongSelections.remove(index); // 올바른 선택 시 잘못된 선택 제거
      } else {
        _wrongSelections.add(index);
        _choices[index]?.remove(letter);
        Vibration.vibrate(duration: 200);
      }
    });

    if (!_displayWord.contains("_")) {
      _stopwatch.stop();
      _totalElapsedTime += _stopwatch.elapsed.inSeconds; // 전체 시간 합산
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    setState(() {
      _isDialogOpen = true;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("단어 완성!"),
          content: Text(
              "걸린 시간: ${_stopwatch.elapsed.inSeconds}초\n시도 횟수: $_attempts번"),
          actions: [
            TextButton(
              child: Text("다음 단어"),
              onPressed: () {
                Navigator.of(context).pop();
                _moveToNextWord();
              },
            ),
            TextButton(
              child: Text("처음 화면으로"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isDialogOpen = false;
      });
    });
  }

  void _moveToNextWord() {
    if (_currentWordIndex < _words.length - 1) {
      setState(() {
        _currentWordIndex++;
        _setWord();
        _stopwatch.reset();
        _stopwatch.start();
      });
      _speakWord(3);  // 다음 단어 읽기
    } else {
      _showFinalResultDialog();
    }
  }

  void _showFinalResultDialog() {
    setState(() {
      _isDialogOpen = true;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("모든 단어 완성!"),
          content: Text(
              "총 걸린 시간: $_totalElapsedTime초\n총 시도 횟수: $_attempts번"),
          actions: [
            TextButton(
              child: Text("다시 풀기"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentWordIndex = 0;
                  _attempts = 0;
                  _totalElapsedTime = 0;
                  _stopwatch.reset();
                  _stopwatch.start();
                  _setWord();
                });
              },
            ),
            TextButton(
              child: Text("처음 화면으로"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isDialogOpen = false;
      });
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("단어 채우기"),
        ),
        body: Center(
          child: Text("설정에서 단어를 추가해주세요."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("단어 채우기"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "단어: ${_displayWord.join(' ')}",
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              "진행 상황: ${_currentWordIndex + 1}/${_words.length}",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _choices.keys.length,
                itemBuilder: (context, index) {
                  int choiceIndex = _choices.keys.elementAt(index);
                  return Column(
                    children: [
                      Text(
                        "위치 ${choiceIndex + 1}의 글자를 선택하세요",
                        style: TextStyle(fontSize: 18),
                      ),
                      Wrap(
                        children: _choices[choiceIndex]!.map((letter) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ElevatedButton(
                              onPressed: () => _onLetterSelected(choiceIndex, letter),
                              child: Text(letter),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_wrongSelections.contains(choiceIndex)) // 잘못된 선택 표시
                        Text(
                          "잘못된 선택입니다.",
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _speakWord(1);
              },
              child: Text("단어 다시 듣기"),
            ),
          ],
        ),
      ),
    );
  }
}
