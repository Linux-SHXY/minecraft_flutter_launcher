import 'package:flutter/material.dart';
import 'game_server/game_download_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luminous_minecraft_launcher',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => gameDownloadPage()),
            );
          },
          child: Text(
            'Welcome to Luminous_minecraft_launcher',
            style: TextStyle(
              backgroundColor: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 136, 51, 255),
            ),
          ),
        ),
      ),
    );
  }
}
