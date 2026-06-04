import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hide_app_state.dart';

class HideAppController extends ChangeNotifier {
  // ================= STORAGE KEYS =================
  static const String _hiddenKey = 'hide_app_enabled';
  static const String _dialCodeKey = 'hide_app_dial_code';
  static const String _iosUnlockedKey = 'ios_stealth_unlocked';

  // Android channel (UNCHANGED)
  static const MethodChannel _androidChannel = MethodChannel('hide_app');

  // iOS icon switch channel (NEW)
  static const MethodChannel _iosIconChannel =
  MethodChannel('hidra_app_icon');

  // ================= STATE =================
  HideAppState _state = const HideAppState();
  HideAppState get state => _state;

  bool get isHidden => _state.isHidden;
  String get dialCode => _state.dialCode;

  // ================= INIT =================
  HideAppController() {
    _load();
  }

  // ================= LOAD =================
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    _state = _state.copyWith(
      isHidden: prefs.getBool(_hiddenKey) ?? false,
      dialCode: prefs.getString(_dialCodeKey) ?? '*#*#13710#*#*',
    );

    notifyListeners();
  }

  // ================= TOGGLE HIDE =================
  Future<bool> toggleHidden(bool hide) async {
    final prefs = await SharedPreferences.getInstance();

    // ---------- ANDROID ----------
    if (Platform.isAndroid) {
      try {
        await _androidChannel.invokeMethod(hide ? 'hide' : 'show');
        await prefs.setBool(_hiddenKey, hide);

        _state = _state.copyWith(isHidden: hide);
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint("Android hide error: $e");
        return false;
      }
    }

    // ---------- IOS ----------
    try {
      final alreadyHidden = prefs.getBool(_hiddenKey) ?? false;

      // If same state → do nothing (prevents iOS crash)
      if (alreadyHidden == hide) {
        return true;
      }

      await prefs.setBool(_hiddenKey, hide);

      if (hide) {
        await prefs.setBool(_iosUnlockedKey, false);

        try {
          await _iosIconChannel.invokeMethod('setIcon', 'phone');
        } catch (_) {
          // ignore iOS duplicate icon error
        }

        await Future.delayed(const Duration(milliseconds: 700));
        SystemNavigator.pop();
      } else {
        try {
          await _iosIconChannel.invokeMethod('setIcon', null);
        } catch (_) {}
      }

      _state = _state.copyWith(isHidden: hide);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("iOS stealth error: $e");
      return false;
    }
  }

  // ================= IOS HELPERS =================

  static Future<void> markIOSUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_iosUnlockedKey, true);
  }

  static Future<bool> canOpenIOSVault() async {
    if (!Platform.isIOS) return true;

    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getBool(_hiddenKey) ?? false;
    final unlocked = prefs.getBool(_iosUnlockedKey) ?? false;

    if (!hidden) return true;
    return unlocked;
  }

  // ================= UPDATE DIAL CODE =================
  Future<bool> updateDialCode(String code) async {
    final cleaned = code.trim();

    if (cleaned.isEmpty || cleaned.length < 4) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dialCodeKey, cleaned);

    _state = _state.copyWith(dialCode: cleaned);
    notifyListeners();
    return true;
  }
}