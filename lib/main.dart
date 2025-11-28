import 'package:flutter/material.dart';
import 'game_server/game_download_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Minecraft Launcher', home: MyHomePage());
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: const Color.fromARGB(255, 136, 51, 255),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 136, 51, 255),
              ),
              child: Text(
                'Minecraft Launcher',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Game Download'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => gameDownloadPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: OutlinedButton(
            onPressed: () {},
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
      ),
    );
  }
}
