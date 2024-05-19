import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'quiz_screen.dart';
import 'local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/quiz': (context) => const QuizScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 맞추기 프로그램'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                debugPrint("Start button pressed");
                Navigator.pushNamed(context, '/quiz');
              },
              child: const Text('퀴즈풀기'),
            ),
            ElevatedButton(
              onPressed: () {
                debugPrint("Settings button pressed");
                Navigator.pushNamed(context, '/settings');
              },
              child: const Text('설정하기'),
            ),
          ],
        ),
      ),
    );
  }
}
