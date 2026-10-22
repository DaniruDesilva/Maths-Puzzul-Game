import 'dart:io' show Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static AudioPlayer? _bgmPlayerInstance;
  
  static List<AudioPlayer>? _sfxPool;
  static List<AudioPlayer> get _pool {
    if (_sfxPool != null) return _sfxPool!;
    try {
      return _sfxPool = List.generate(5, (_) {
        try {
          return AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
        } catch (_) {
          return AudioPlayer();
        }
      });
    } catch (_) {
      return _sfxPool = [];
    }
  }
  static int _sfxPoolIndex = 0;
  
  static bool get _isInTest {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  static bool _soundEnabled = !_isInTest;
  static bool _musicEnabled = !_isInTest;

  static bool get isSoundEnabled => _soundEnabled;
  static bool get isMusicEnabled => _musicEnabled;

  static String _currentBgm = '';
  static String _lastActiveBgm = '';
  static bool _isPausedByLifecycle = false;
  static AppLifecycleListener? _lifecycleListener;
  
  static const MethodChannel _nativeAudioChannel =
      MethodChannel('com.creatorboxstudios.numberhaven/audio_lifecycle');

  static void _setupNativeLifecycleListener() {
    _nativeAudioChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'pauseAudio':
          await pauseAmbience();
          break;
        case 'resumeAudio':
          await resumeAmbience();
          break;
      }
    });
  }

  static AudioContext get _gameAudioContext => AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('setting_sound') ?? true;
      _musicEnabled = prefs.getBool('setting_music') ?? true;
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }

    if (!_isInTest) {
      // Connect to native Android lifecycle channel (from MainActivity.kt)
      _setupNativeLifecycleListener();

      try {
        await AudioPlayer.global.setAudioContext(_gameAudioContext);
      } catch (e) {
        debugPrint('SoundService setAudioContext error: $e');
      }

      // Engine-level lifecycle listener for backgrounding & screen lock
      try {
        _lifecycleListener?.dispose();
        _lifecycleListener = AppLifecycleListener(
          onPause: () => pauseAmbience(),
          onHide: () => pauseAmbience(),
          onInactive: () => pauseAmbience(),
          onResume: () => resumeAmbience(),
          onDetach: () => pauseAmbience(),
        );
      } catch (e) {
        debugPrint('SoundService AppLifecycleListener error: $e');
      }
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
      _lastActiveBgm = '';
      _isPausedByLifecycle = false;
      await _disposeBgmPlayer();
    } else {
      _currentBgm = '';
      await playVillageMusic();
    }
  }

  // Play simple system click for immediate UI feedback without needing assets
  static void playClick() {
    if (!_soundEnabled || _isInTest) return;
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  static Future<void> playSfx(String fileName) async {
    if (!_soundEnabled || _isInTest) return;
    try {
      final pool = _pool;
      if (pool.isEmpty) {
        playClick();
        return;
      }
      final player = pool[_sfxPoolIndex];
      _sfxPoolIndex = (_sfxPoolIndex + 1) % pool.length;
      await player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      playClick();
    }
  }

  /// Safely disposes and clears the active BGM player to prevent Android MediaPlayer state corruption (Error -38)
  static Future<void> _disposeBgmPlayer() async {
    final player = _bgmPlayerInstance;
    _bgmPlayerInstance = null;
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {}
      try {
        await player.release();
      } catch (_) {}
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  /// Internal BGM play coordinator ensuring clean, idempotent transitions without MediaPlayer crashes
  static Future<void> _playBgm(String trackName, String assetPath) async {
    if (!_musicEnabled || _isInTest) return;
    if (_currentBgm == trackName && _bgmPlayerInstance != null) {
      return; // Track is already playing
    }

    _currentBgm = trackName;
    _lastActiveBgm = trackName;
    _isPausedByLifecycle = false;

    try {
      await _disposeBgmPlayer();

      if (!_musicEnabled || _isInTest) return;

      final player = AudioPlayer();
      _bgmPlayerInstance = player;

      try {
        await player.setAudioContext(_gameAudioContext);
      } catch (_) {}

      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1.0);

      await player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('BGM Play Error ($trackName): $e');
      _currentBgm = '';
      await _disposeBgmPlayer();
    }
  }

  static Future<void> playVillageMusic() async {
    await _playBgm('village', 'sounds/tavern_music.mp3');
  }

  static Future<void> playBiomeAmbience(int biomeId) async {
    await _playBgm('biome_$biomeId', 'sounds/ambience_biome_$biomeId.mp3');
  }

  static Future<void> stopAmbience() async {
    _currentBgm = '';
    _lastActiveBgm = '';
    _isPausedByLifecycle = false;
    await _disposeBgmPlayer();
  }

  static Future<void> pauseAmbience() async {
    if (_isInTest) return;
    if (_isPausedByLifecycle) return;
    _isPausedByLifecycle = true;

    // Immediately silence any active SFX
    if (_sfxPool != null) {
      for (final player in _sfxPool!) {
        try {
          player.stop();
        } catch (_) {}
      }
    }

    if (_currentBgm.isNotEmpty) {
      _lastActiveBgm = _currentBgm;
    }

    // Completely release and dispose the BGM player to guarantee silence at the Android OS driver level.
    // Disposing calls native mediaPlayer.reset() and mediaPlayer.release(), killing the hardware audio track.
    await _disposeBgmPlayer();
  }

  static Future<void> resumeAmbience() async {
    if (_isInTest) return;
    if (!_isPausedByLifecycle) return;
    _isPausedByLifecycle = false;

    if (!_musicEnabled) return;

    final trackToResume = _lastActiveBgm.isNotEmpty ? _lastActiveBgm : _currentBgm;
    if (trackToResume.isEmpty) return;

    // Clean restart with fresh player instance
    final bgm = trackToResume;
    _currentBgm = '';
    if (bgm == 'village') {
      await playVillageMusic();
    } else if (bgm.startsWith('biome_')) {
      final biomeId = int.tryParse(bgm.replaceFirst('biome_', '')) ?? 0;
      await playBiomeAmbience(biomeId);
    }
  }

  static void playThwack() => playSfx('thwack.wav');
  static void playSuccess() => playSfx('success.wav');
  static void playFailure() => playSfx('failure.wav');
  static void playCombo(int combo) => playSfx('success.wav');
  static void playBonus() => playSfx('success.wav');
  static void playLevelComplete() => playSfx('level_complete.wav');
}
