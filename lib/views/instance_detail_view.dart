import 'dart:io';
import 'package:flutter/material.dart';
import '../components/anime_button.dart';
import '../components/anime_card.dart';
import '../models/instance_model.dart';
import '../services/instance_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';

class InstanceDetailView extends StatefulWidget {
  final String instanceId;
  const InstanceDetailView({Key? key, required this.instanceId}) : super(key: key);
  @override
  State<InstanceDetailView> createState() => _InstanceDetailViewState();
}

class _InstanceDetailViewState extends State<InstanceDetailView> {
  final InstanceManager _instanceManager = InstanceManager();
  InstanceModel? _instance;
  bool _isLoading = true;
  bool _isLaunching = false;

  @override
  void initState() { super.initState(); _loadInstance(); }

  Future<void> _loadInstance() async {
    setState(() { _isLoading = true; });
    try { final instance = await _instanceManager.getInstance(widget.instanceId); setState(() { _instance = instance; }); } catch (e) { print('Failed to load instance: $e'); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载实例失败: $e'))); } finally { setState(() { _isLoading = false; }); }
  }

  Future<void> _launchInstance() async { if (_instance == null) return; setState(() { _isLaunching = true; }); try { await _instanceManager.launchInstance(_instance!); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('实例启动成功'))); } catch (e) { print('Failed to launch instance: $e'); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('启动实例失败: $e'))); } finally { setState(() { _isLaunching = false; }); } }

  Future<void> _deleteInstance() async { if (_instance == null) return; final confirm = await showDialog<bool>(context: context, builder: (context) { return AlertDialog(title: const Text('删除实例'), content: Text('确定要删除实例 "${_instance!.name}" 吗？此操作不可恢复。'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('删除')), ],); },); if (confirm == true) { try { await _instanceManager.deleteInstance(widget.instanceId); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('实例删除成功'))); Navigator.pop(context); } catch (e) { print('Failed to delete instance: $e'); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除实例失败: $e'))); } } }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_instance == null) return Scaffold(body: Center(child: Text('Instance not found')));
    return Scaffold(
      appBar: AppBar(title: Text(_instance!.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          AnimeCard(title: _instance!.name, subtitle: 'Version: ${_instance!.minecraftVersion}', icon: const Icon(Icons.gamepad), onTap: () {}),
          const SizedBox(height: 12),
          Row(children: [AnimeButton(text: 'Launch', onPressed: _launchInstance), const SizedBox(width: 8), AnimeButton(text: 'Delete', onPressed: _deleteInstance, isPrimary: false)]),
        ]),
      ),
    );
  }
}
