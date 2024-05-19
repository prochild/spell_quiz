import 'package:flutter/material.dart';
import 'package:spell_quiz/quiz_screen.dart';
import 'package:spell_quiz/settings_screen.dart';
import 'package:spell_quiz/fill_in_the_blanks_screen.dart';
import 'local_storage.dart'; // 로컬 저장소 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init(); // 로컬 저장소 초기화
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spell Quiz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
      routes: {
        '/quiz': (context) => QuizScreen(),
        '/fillInTheBlanks': (context) => FillInTheBlanksScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spell Quiz'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/quiz');
              },
              child: Text('퀴즈풀기'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/fillInTheBlanks');
              },
              child: Text('빈칸 채우기'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              child: Text('설정하기'),
            ),
          ],
        ),
      ),
    );
  }
}
