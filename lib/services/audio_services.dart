import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  // Música de fondo
  final AudioPlayer _bg = AudioPlayer(playerId: 'bg')
    ..setReleaseMode(ReleaseMode.loop);

  // Efectos
  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx')
    ..setReleaseMode(ReleaseMode.stop);

  /// Reproduce la música de fondo con manejo de errores
  Future<void> playBackground() async {
    try {
      await _bg.play(AssetSource('sounds/themesound.mp3'), volume: 0.3);
    } catch (e, st) {
      debugPrint('Error al reproducir música de fondo: $e\n$st');
    }
  }

  /// Pausa la música de fondo con manejo de errores
  Future<void> pauseBackground() async {
    try {
      await _bg.pause();
    } catch (e, st) {
      debugPrint('Error al pausar música de fondo: $e\n$st');
    }
  }

  /// Reanuda la música de fondo con manejo de errores
  Future<void> resumeBackground() async {
    try {
      await _bg.resume();
    } catch (e, st) {
      debugPrint('Error al reanudar música de fondo: $e\n$st');
    }
  }

  /// Detiene la música de fondo con manejo de errores
  Future<void> stopBackground() async {
    try {
      await _bg.stop();
    } catch (e, st) {
      debugPrint('Error al detener música de fondo: $e\n$st');
    }
  }

  /// Reproduce un efecto de sonido SFX, con verificación y manejo de errores
  Future<void> playSfx(String fileName) async {
    try {
      // Verificar que el asset exista
      await rootBundle.load('assets/sounds/$fileName.mp3');
      // Reproducir SFX
      await _sfx.play(AssetSource('sounds/$fileName.mp3'), volume: 1.0);
    } catch (e, st) {
      debugPrint('Error al reproducir SFX "$fileName": $e\n$st');
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
      debugPrint('Error al liberar AudioService: $e\n$st');
    }
  }
}
