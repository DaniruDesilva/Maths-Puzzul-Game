import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  
  static List<AudioPlayer>? _sfxPool;
  static List<AudioPlayer> get _pool {
    return _sfxPool ??= List.generate(5, (_) {
      try {
        return AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      } catch (_) {
        return AudioPlayer();
      }
    });
  }
  static int _sfxPoolIndex = 0;
  
  static bool _soundEnabled = true;
  static bool _musicEnabled = true;

  static bool get isSoundEnabled => _soundEnabled;
  static bool get isMusicEnabled => _musicEnabled;
  
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('setting_sound') ?? true;
      _musicEnabled = prefs.getBool('setting_music') ?? true;
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }
  }
  
  static void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled && _sfxPool != null) {
      for (var player in _sfxPool!) {
        try {
          player.stop();
        } catch (_) {}
      }
    }
  }

  static void setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled) {
      _currentBgm = '';
      try {
        await _bgmPlayer.stop();
        await _bgmPlayer.release();
      } catch (e) {
        // Ignore audio release errors
      }
    } else {
      // If re-enabled, resume village music by default
      playVillageMusic();
    }
  }

  // Play simple system click for immediate UI feedback without needing assets
  static void playClick() {
    if (!_soundEnabled) return;
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  static Future<void> playSfx(String fileName) async {
    if (!_soundEnabled) return;
    try {
      final player = _pool[_sfxPoolIndex];
      _sfxPoolIndex = (_sfxPoolIndex + 1) % _pool.length;
      await player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      // Gracefully handle missing assets during development
      playClick();
    }
  }

  static String _currentBgm = '';

  static Future<void> playVillageMusic() async {
    if (!_musicEnabled) return;
    if (_currentBgm == 'village') return; // Already playing
    try {
      _currentBgm = 'village';
      await stopAmbience(); // Safely stop
      if (!_musicEnabled) return;
      _currentBgm = 'village'; // Re-set because stopAmbience clears it
      await _bgmPlayer.setSource(AssetSource('sounds/tavern_music.mp3'));
      if (!_musicEnabled) {
        await _bgmPlayer.release();
        return;
      }
      await _bgmPlayer.setVolume(1.0);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.resume();
    } catch (e) {
      debugPrint('BGM Error (Village): $e');
      _currentBgm = ''; // Reset state if failed
    }
  }

  static Future<void> playBiomeAmbience(int biomeId) async {
    if (!_musicEnabled) return;
    if (_currentBgm == 'biome_$biomeId') return; // Already playing
    try {
      _currentBgm = 'biome_$biomeId';
      String fileName = 'ambience_biome_$biomeId.mp3';
      await stopAmbience(); // Safely stop
      if (!_musicEnabled) return;
      _currentBgm = 'biome_$biomeId';
      await _bgmPlayer.setSource(AssetSource('sounds/$fileName'));
      if (!_musicEnabled) {
        await _bgmPlayer.release();
        return;
      }
      await _bgmPlayer.setVolume(1.0);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.resume();
    } catch (e) {
      debugPrint('BGM Error (Biome): $e');
      _currentBgm = ''; // Reset state if failed
    }
  }

  static Future<void> stopAmbience() async {
    _currentBgm = '';
    try {
      await _bgmPlayer.release();
    } catch (e) {
      // Ignore audio release errors
    }
  }

  static void pauseAmbience() async {
    if (_musicEnabled) {
      try {
        await _bgmPlayer.pause();
      } catch (e) {
        // Ignore audio pause errors
      }
    }
  }

  static void resumeAmbience() async {
    if (_musicEnabled && _currentBgm.isNotEmpty) {
      try {
        await _bgmPlayer.resume();
      } catch (e) {
        // If resume fails, try playing it directly
        if (_currentBgm == 'village') {
          playVillageMusic();
        }
      }
    }
  }

  static void playThwack() => playSfx('thwack.wav');
  static void playSuccess() => playSfx('success.wav');
  static void playFailure() => playSfx('failure.wav');
  static void playCombo(int combo) => playSfx('success.wav'); // Fallback
  static void playLevelComplete() => playSfx('level_complete.wav');
}
