import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../settings_manager.dart';

class SettingPage extends StatefulWidget {
  final VoidCallback onThemeUpdated;
  const SettingPage({super.key, required this.onThemeUpdated});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final SettingsManager _settingsManager = SettingsManager();
  String _selectedColorName = 'Deep Purple';
  String _downloadPath = '';
  String _javaPath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final colorName = await _settingsManager.getThemeColor();
    final path = await _settingsManager.getDownloadPath();
    final javaPath = await _settingsManager.getJavaPath();
    setState(() {
      _selectedColorName = colorName;
      _downloadPath = path;
      _javaPath = javaPath;
      _isLoading = false;
    });
  }

  Future<void> _selectDownloadDirectory() async {
    try {
      final String? selectedDirectory = await FilePicker.platform
          .getDirectoryPath();

      if (selectedDirectory != null && mounted) {
        setState(() {
          _downloadPath = selectedDirectory;
        });
        await _settingsManager.setDownloadPath(selectedDirectory);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('下载目录已设置为: $selectedDirectory'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择目录失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildThemeColorSection(),
          const SizedBox(height: 24),
          _buildDownloadPathSection(),
          const SizedBox(height: 24),
          _buildJavaPathSection(),
        ],
      ),
    );
  }

  Widget _buildThemeColorSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.palette, color: Color.fromARGB(255, 136, 51, 255)),
                SizedBox(width: 8),
                Text(
                  '主题颜色',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: SettingsManager.availableColors.map((colorOption) {
                final isSelected = _selectedColorName == colorOption.name;
                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedColorName = colorOption.name;
                    });
                    await _settingsManager.setThemeColor(colorOption.name);
                    _refreshAppTheme();
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorOption.displayColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              '当前选择: $_selectedColorName',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectJavaPath() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['exe'],
        dialogTitle: '选择Java可执行文件',
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        final selectedPath = result.files.single.path!;
        setState(() {
          _javaPath = selectedPath;
        });
        await _settingsManager.setJavaPath(selectedPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Java路径已设置为: $selectedPath'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择Java路径失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildDownloadPathSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.folder, color: Color.fromARGB(255, 136, 51, 255)),
                SizedBox(width: 8),
                Text(
                  '游戏下载目录',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _downloadPath.isEmpty ? '未设置下载目录' : _downloadPath,
                      style: TextStyle(
                        fontSize: 14,
                        color: _downloadPath.isEmpty
                            ? Colors.grey[500]
                            : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectDownloadDirectory,
                icon: const Icon(Icons.folder_open),
                label: const Text('选择下载目录'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 136, 51, 255),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '提示: 下载的游戏将保存在此目录中',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJavaPathSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.code, color: Color.fromARGB(255, 136, 51, 255)),
                SizedBox(width: 8),
                Text(
                  'Java路径',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _javaPath.isEmpty ? '未设置Java路径' : _javaPath,
                      style: TextStyle(
                        fontSize: 14,
                        color: _javaPath.isEmpty
                            ? Colors.grey[500]
                            : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectJavaPath,
                icon: const Icon(Icons.file_open),
                label: const Text('选择Java路径'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 136, 51, 255),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '提示: 默认使用系统Java路径',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshAppTheme() {
    widget.onThemeUpdated();
  }
}
