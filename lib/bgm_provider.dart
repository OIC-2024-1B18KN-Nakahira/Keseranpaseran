import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final bgmPlayerProvider = Provider<AudioPlayer>((ref) {
  return AudioPlayer();
});

final bgmVolumeProvider = StateProvider<double>((ref) {
  return 0.1; // デフォルト音量を10%に設定
});

class BgmVolumeNotifier extends StateNotifier<double> {
  BgmVolumeNotifier() : super(0.5) {
    _loadVolume();
  }

  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble('bgm_volume') ?? 0.5;
  }

  Future<void> setVolume(double volume) async {
    state = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bgm_volume', volume);
  }
}
