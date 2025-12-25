import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/vault_file.dart';

enum VaultSortType {
  nameAsc,
  nameDesc,
  dateNewest,
  dateOldest,
  sizeAsc,
  sizeDesc,
  reset,
}

class VaultController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  final List<VaultFile> _files = [];
  final Set<VaultFile> _selectedFiles = {};

  bool _isImporting = false;

  static const String _dbKey = 'vault_files';

  // ================= GETTERS =================

  List<VaultFile> get files => List.unmodifiable(_files);
  List<VaultFile> get selectedFiles => List.unmodifiable(_selectedFiles);

  bool get isEmpty => _files.isEmpty;
  bool get isImporting => _isImporting;
  bool get isSelectionMode => _selectedFiles.isNotEmpty;

  int get selectedCount => _selectedFiles.length;
  int get totalFiles => _files.length;

  // ================= IMPORT =================

  Future<void> importFromGallery({bool deleteOriginals = false}) async {
    if (_isImporting) return;

    try {
      _isImporting = true;
      notifyListeners();

      final picked = await _picker.pickMultipleMedia();
      if (picked.isEmpty) return;

      for (final x in picked) {
        final file = File(x.path);
        if (!file.existsSync()) continue;

        // prevent duplicates
        if (_files.any((f) => f.file.path == file.path)) continue;

        final isVideo = x.mimeType?.startsWith('video') ?? false;

        final vaultFile = VaultFile(
          file: file,
          importedAt: DateTime.now(),
          type: isVideo ? VaultFileType.video : VaultFileType.image,
        );

        _files.add(vaultFile);

        if (deleteOriginals) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }

      await saveFiles();
    } catch (e) {
      debugPrint('❌ Vault import error: $e');
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  // ================= SORT =================

  void sortFiles(VaultSortType type) {
    switch (type) {
      case VaultSortType.nameAsc:
        _files.sort((a, b) =>
            a.file.path.toLowerCase().compareTo(b.file.path.toLowerCase()));
        break;

      case VaultSortType.nameDesc:
        _files.sort((a, b) =>
            b.file.path.toLowerCase().compareTo(a.file.path.toLowerCase()));
        break;

      case VaultSortType.dateNewest:
        _files.sort((a, b) => b.importedAt.compareTo(a.importedAt));
        break;

      case VaultSortType.dateOldest:
        _files.sort((a, b) => a.importedAt.compareTo(b.importedAt));
        break;

      case VaultSortType.sizeAsc:
        _files.sort((a, b) =>
            a.file.lengthSync().compareTo(b.file.lengthSync()));
        break;

      case VaultSortType.sizeDesc:
        _files.sort((a, b) =>
            b.file.lengthSync().compareTo(a.file.lengthSync()));
        break;

      case VaultSortType.reset:
        _files.sort((a, b) => a.importedAt.compareTo(b.importedAt));
        break;
    }

    notifyListeners();
  }

  // ================= SELECTION =================

  bool isSelected(VaultFile file) => _selectedFiles.contains(file);

  void toggleSelection(VaultFile file) {
    _selectedFiles.contains(file)
        ? _selectedFiles.remove(file)
        : _selectedFiles.add(file);
    notifyListeners();
  }

  void clearSelection() {
    _selectedFiles.clear();
    notifyListeners();
  }

  void selectAll() {
    _selectedFiles
      ..clear()
      ..addAll(_files);
    notifyListeners();
  }

  // ================= DELETE =================

  void deleteSelected() {
    _files.removeWhere(_selectedFiles.contains);
    _selectedFiles.clear();
    saveFiles();
    notifyListeners();
  }

  void removeFile(VaultFile file) {
    _files.remove(file);
    _selectedFiles.remove(file);
    saveFiles();
    notifyListeners();
  }

  void clearVault() {
    _files.clear();
    _selectedFiles.clear();
    saveFiles();
    notifyListeners();
  }

  // ================= STORAGE =================

  Future<void> saveFiles() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = _files.map((f) => f.toJson()).toList();

    await prefs.setString(
      _dbKey,
      jsonEncode(jsonList),
    );

    debugPrint('✅ Vault saved: ${_files.length} files');
  }

  Future<void> loadFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dbKey);

    if (raw == null) return;

    try {
      final List decoded = jsonDecode(raw);

      _files
        ..clear()
        ..addAll(
          decoded
              .map<VaultFile>((e) => VaultFile.fromJson(e))
              .where((v) => v.file.existsSync()),
        );

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Vault load error: $e');
    }
  }

  // ================= INIT =================

  VaultController() {
    loadFiles();
  }
}
