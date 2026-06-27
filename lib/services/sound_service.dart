import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playHonorUp() async {
    try {
      await _player.play(AssetSource('sounds/honor_up.mp3'));
    } catch (_) {}
  }

  static Future<void> playHonorDown() async {
    try {
      await _player.play(AssetSource('sounds/honor_down.mp3'));
    } catch (_) {}
  }

  static Future<void> dispose() async {
    await _player.dispose();
  }
}
