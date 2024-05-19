import 'package:flutter/material.dart';
import 'local_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _wordController = TextEditingController();
  List<String> _words = [];

  @override
  void initState() {
    super.initState();
    _words = LocalStorage.getWords();
  }

  void _saveSettings() {
    LocalStorage.setWords(_words);
    Navigator.pop(context);
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
            TextField(
              controller: _wordController,
              decoration: const InputDecoration(
                labelText: '단어 입력',
              ),
              onSubmitted: (value) {
                setState(() {
                  _words.add(value);
                  _wordController.clear();
                });
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _words.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_words[index]),
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
