import 'package:flutter/material.dart';
import 'local_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _wordController = TextEditingController();
  List<TextEditingController> _wordControllers = [];
  int _numWords = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _numWords = LocalStorage.getWords().length;
    _wordControllers = List.generate(_numWords, (index) => TextEditingController());
    for (int i = 0; i < _numWords; i++) {
      _wordControllers[i].text = LocalStorage.getWords()[i];
    }
  }

  void _saveSettings() {
    List<String> words = _wordControllers.map((controller) => controller.text).toList();
    LocalStorage.setWords(words);
    Navigator.pop(context);
  }

  void _setNumWords(int num) {
    setState(() {
      _numWords = num;
      _wordControllers = List.generate(_numWords, (index) => TextEditingController());
    });
  }

  void _incrementNumWords() {
    setState(() {
      _numWords++;
      _wordControllers.add(TextEditingController());
    });
  }

  void _decrementNumWords() {
    if (_numWords > 0) {
      setState(() {
        _numWords--;
        _wordControllers.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정하기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _numWords.toString()),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '문제의 갯수'),
                    onSubmitted: (value) {
                      _setNumWords(int.parse(value));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _incrementNumWords,
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _decrementNumWords,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child: const Text('설정하기'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _numWords,
                itemBuilder: (context, index) {
                  return TextField(
                    controller: _wordControllers[index],
                    decoration: InputDecoration(labelText: '단어 ${index + 1}'),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('설정 저장하기'),
            ),
          ],
        ),
      ),
    );
  }
}
