import 'package:flutter_test/flutter_test.dart';
import 'package:number_haven/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundService Lifecycle & Settings Tests', () {
    setUp(() {
      SoundService.setSoundEnabled(true);
      SoundService.setMusicEnabled(true);
    });

    test('Sound and Music toggling updates internal enabled states', () {
      expect(SoundService.isSoundEnabled, isTrue);
      expect(SoundService.isMusicEnabled, isTrue);

      SoundService.setSoundEnabled(false);
      expect(SoundService.isSoundEnabled, isFalse);

      SoundService.setMusicEnabled(false);
      expect(SoundService.isMusicEnabled, isFalse);
    });

    test('Lifecycle pauseAmbience and resumeAmbience execute safely without throwing', () async {
      // Rapid sequential calls simulating Android inactive -> hidden -> paused
      await SoundService.pauseAmbience();
      await SoundService.pauseAmbience();
      await SoundService.pauseAmbience();

      // Resume on return to app
      await SoundService.resumeAmbience();
      await SoundService.resumeAmbience();

      // Calling stopAmbience clears states cleanly
      await SoundService.stopAmbience();
    });

    test('SFX methods execute safely when muted or unmuted', () {
      SoundService.setSoundEnabled(true);
      SoundService.playClick();
      SoundService.playThwack();
      SoundService.playSuccess();
      SoundService.playFailure();
      SoundService.playCombo(3);
      SoundService.playBonus();
      SoundService.playLevelComplete();

      SoundService.setSoundEnabled(false);
      SoundService.playClick();
      SoundService.playThwack();
      SoundService.playSuccess();
      SoundService.playFailure();
    });
  });
}
