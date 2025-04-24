import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  // Volumen actual (0.0 a 1.0)
  double _volume = 0.3;
AudioService() {
    // Listener para el bg player
    _bg.onPlayerStateChanged.listen((state) {
      debugPrint('🔊 AudioService background state: $state');
    });
    // Listener de errores
    _bg.onPlayerComplete.listen((_) {
      debugPrint('🔊 AudioService: bg playback completed');
    });
  }

  Future<void> playBackground() async {
    debugPrint('🔊 playBackground() llamado, volumen=$_volume');
    try {
      await _bg.setVolume(_volume);
      await _bg.play(AssetSource('sounds/themesound.mp3'));
    } catch (e, st) {
      debugPrint('❌ Error al reproducir música de fondo: $e\n$st');
    }
  }
  // Música de fondo
  final AudioPlayer _bg = AudioPlayer(playerId: 'bg')
    ..setReleaseMode(ReleaseMode.loop);

  // Efectos
  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx')
    ..setReleaseMode(ReleaseMode.stop);

  /// Obtiene el volumen actual
  double get currentVolume => _volume;

  /// Ajusta el volumen de la música de fondo
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    try {
      await _bg.setVolume(_volume);
    } catch (e, st) {
      debugPrint('Error al ajustar volumen de fondo: \$e\n\$st');
    }
  }

  
  /// Pausa la música de fondo con manejo de errores
  Future<void> pauseBackground() async {
    try {
      await _bg.pause();
    } catch (e, st) {
      debugPrint('Error al pausar música de fondo: \$e\n\$st');
    }
  }

  /// Reanuda la música de fondo con manejo de errores
  Future<void> resumeBackground() async {
    try {
      await _bg.resume();
      await _bg.setVolume(_volume);
    } catch (e, st) {
      debugPrint('Error al reanudar música de fondo: \$e\n\$st');
    }
  }

  /// Detiene la música de fondo con manejo de errores
  Future<void> stopBackground() async {
    try {
      await _bg.stop();
    } catch (e, st) {
      debugPrint('Error al detener música de fondo: \$e\n\$st');
    }
  }

  /// Reproduce un efecto de sonido SFX, con verificación y manejo de errores
  Future<void> playSfx(String fileName) async {
    try {
      // Verificar que el asset exista
      await rootBundle.load('assets/sounds/$fileName.mp3');
      // Reproducir SFX
      await _sfx.play(AssetSource('sounds/$fileName.mp3'));
    } catch (e, st) {
      debugPrint('Error al reproducir SFX "\$fileName": \$e\n\$st');
      // Opcional: reanudar fondo si se pausó por el SFX
      try {
        await resumeBackground();
      } catch (_) {}
    }
  }

  /// Stream de estado para saber cuándo el SFX completa
  Stream<PlayerState> get onSfxStateChanged => _sfx.onPlayerStateChanged;

  /// Libera recursos del AudioService
  void dispose() {
    try {
      _bg.dispose();
      _sfx.dispose();
    } catch (e, st) {
      debugPrint('Error al liberar AudioService: \$e\n\$st');
    }
  }
}
