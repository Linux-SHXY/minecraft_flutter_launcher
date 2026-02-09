import 'package:flutter/material.dart';
import '../components/anime_button.dart';
import '../components/anime_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BAMCLauncher'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                '欢迎使用 BAMCLauncher',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 8),
              const Text('轻量跨平台、二次元风格的 Minecraft 启动器', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AnimeButton(text: '新建实例', onPressed: () {}),
                  AnimeButton(text: '导入整合包', onPressed: () {}, isPrimary: false),
                ],
              ),
              const SizedBox(height: 32),
              const Text('我的实例', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              AnimeCard(title: 'Example Instance', subtitle: 'Minecraft 1.19.4 - Fabric 0.15.3', icon: const Icon(Icons.gamepad, size: 40, color: Color(0xFF3B82F6)), onTap: () {}),
              const SizedBox(height: 16),
              AnimeCard(title: 'Creative World', subtitle: 'Minecraft 1.20.1 - Forge 47.2.0', icon: const Icon(Icons.brush, size: 40, color: Color(0xFFF472B6)), onTap: () {}),
              const SizedBox(height: 32),
              const Text('P2P 联机', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              AnimeCard(title: '创建房间', subtitle: '创建一个新的 P2P 联机房间', icon: const Icon(Icons.add_box, size: 40, color: Color(0xFF34D399)), onTap: () {}),
              const SizedBox(height: 16),
              AnimeCard(title: '加入房间', subtitle: '通过房间 ID 或二维码加入房间', icon: const Icon(Icons.qr_code_scanner, size: 40, color: Color(0xFFF59E0B)), onTap: () {}),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
