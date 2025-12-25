import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/vault_file.dart';
import '../../vault/utils/video_thumbnail_helper.dart';

class VaultPickerScreen extends StatefulWidget {
  final String albumId;

  const VaultPickerScreen({
    super.key,
    required this.albumId,
  });

  @override
  State<VaultPickerScreen> createState() => _VaultPickerScreenState();
}

class _VaultPickerScreenState extends State<VaultPickerScreen> {
  final List<VaultFile> _vaultFiles = [];
  final Set<int> _selectedIndexes = {};

  /// UI-only thumbnail cache (NO persistence)
  final Map<String, File?> _videoThumbCache = {};

  bool _loading = true;

  static const String _dbKey = 'vault_files';

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  // ================= LOAD VAULT (READ ONLY) =================

  Future<void> _loadVault() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dbKey);

    if (raw != null) {
      final List decoded = jsonDecode(raw);
      _vaultFiles
        ..clear()
        ..addAll(
          decoded
              .map<VaultFile>((e) => VaultFile.fromJson(e))
              .where((v) => v.file.existsSync()),
        );
    }

    setState(() => _loading = false);
  }

  // ================= VIDEO THUMB (USING YOUR HELPER) =================

  Future<File?> _getVideoThumb(VaultFile file) async {
    final path = file.file.path;

    if (_videoThumbCache.containsKey(path)) {
      return _videoThumbCache[path];
    }

    final thumb = await VideoThumbnailHelper.generate(
      file.file,
      isEncrypted: file.isEncrypted,
    );

    _videoThumbCache[path] = thumb;
    return thumb;
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF050B18),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _header(),
              const Divider(color: Colors.white12),
              Expanded(child: _content(controller)),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          const Text(
            'Select from Vault',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const Spacer(),
          TextButton(
            onPressed: _selectedIndexes.isEmpty ? null : _onDone,
            child: Text(
              'Add',
              style: TextStyle(
                color: _selectedIndexes.isEmpty
                    ? Colors.white38
                    : const Color(0xFF0FB9B1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(ScrollController controller) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0FB9B1)),
      );
    }

    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _vaultFiles.length,
      itemBuilder: (_, index) {
        final file = _vaultFiles[index];
        final selected = _selectedIndexes.contains(index);
        return _gridItem(file, index, selected);
      },
    );
  }

  // ================= GRID ITEM =================

  Widget _gridItem(VaultFile file, int index, bool selected) {
    return InkWell(
      onTap: () => _toggle(index),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: file.type == VaultFileType.image
                  ? Image.file(file.file, fit: BoxFit.cover)
                  : FutureBuilder<File?>(
                future: _getVideoThumb(file),
                builder: (_, snap) {
                  if (snap.data != null &&
                      snap.data!.existsSync()) {
                    return Image.file(
                      snap.data!,
                      fit: BoxFit.cover,
                    );
                  }
                  return _videoPlaceholder();
                },
              ),
            ),
          ),

          if (file.type == VaultFileType.video)
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white70,
                  size: 36,
                ),
              ),
            ),

          if (selected)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.check_circle,
                color: Color(0xFF0FB9B1),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      color: Colors.black38,
      child: const Center(
        child: Icon(
          Icons.videocam,
          color: Colors.white38,
          size: 32,
        ),
      ),
    );
  }

  // ================= ACTIONS =================

  void _toggle(int index) {
    setState(() {
      _selectedIndexes.contains(index)
          ? _selectedIndexes.remove(index)
          : _selectedIndexes.add(index);
    });
  }

  void _onDone() {
    Navigator.pop(
      context,
      _selectedIndexes.map((i) => _vaultFiles[i]).toList(),
    );
  }
}
