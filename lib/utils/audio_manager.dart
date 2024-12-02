import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart' as audio;

class GlobalAudioManager {
  static final GlobalAudioManager _instance = GlobalAudioManager._internal();
  factory GlobalAudioManager() => _instance;
  
  GlobalAudioManager._internal();

  audio.AudioPlayer? _currentPlayer;
  VoidCallback? _currentStopCallback;

  // Enhanced audio play method with error handling
  Future<void> playAudio({
    required audio.AudioPlayer newPlayer, 
    required String audioUrl, 
    VoidCallback? onStop,
    VoidCallback? onError
  }) async {
    try {
      // Stop and reset current player if exists
      if (_currentPlayer != null) {
        await _currentPlayer!.stop();
        _currentStopCallback?.call();
      }

      // Configure new player
      _currentPlayer = newPlayer;
      _currentStopCallback = onStop;

      // Reset player state
      await newPlayer.stop();
      await newPlayer.setSource(audio.UrlSource(audioUrl));
      
      // Play audio
      await newPlayer.play(audio.UrlSource(audioUrl));
    } catch (e) {
      print('Audio play error: $e');
      onError?.call();
      clearCurrentPlayer();
    }
  }

  // Robust method to clear current player
  void clearCurrentPlayer() {
    _currentPlayer = null;
    _currentStopCallback = null;
  }
}