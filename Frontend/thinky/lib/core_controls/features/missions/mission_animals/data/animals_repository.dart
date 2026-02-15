import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:thinky/core_controls/services/api_client.dart';
import 'package:thinky/core_controls/config/app_config.dart';
import 'animals_models.dart';

/// Repository for Animals Mission API calls
class AnimalsRepository {
  static const String _basePath = '/animals';

  /// Start a new animals mission
  static Future<MissionProgressResponse> startMission() async {
    try {
      final response = await ApiClient.get('$_basePath/start');
      if (response.statusCode == 200) {
        return MissionProgressResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to start mission: ${response.statusCode}');
    } catch (e) {
      debugPrint('AnimalsRepository.startMission error: $e');
      rethrow;
    }
  }

  /// Get current round's image
  static Future<RoundResponse> getRound() async {
    try {
      final response = await ApiClient.get('$_basePath/round');
      if (response.statusCode == 200) {
        return RoundResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to get round: ${response.statusCode}');
    } catch (e) {
      debugPrint('AnimalsRepository.getRound error: $e');
      rethrow;
    }
  }

  /// Pixy makes a guess
  static Future<GuessResponse> makeGuess(String imageId) async {
    try {
      final response = await ApiClient.post('$_basePath/guess', {
        'image_id': imageId,
      });
      if (response.statusCode == 200) {
        return GuessResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to make guess: ${response.statusCode}');
    } catch (e) {
      debugPrint('AnimalsRepository.makeGuess error: $e');
      rethrow;
    }
  }

  /// Verify user's confirmation of Pixy's guess
  static Future<VerifyGuessResponse> verifyGuess({
    required String imageId,
    required String pixyGuess,
    required bool userSaysCorrect,
  }) async {
    try {
      final response = await ApiClient.post('$_basePath/verify-guess', {
        'image_id': imageId,
        'pixy_guess': pixyGuess,
        'user_says_correct': userSaysCorrect,
      });
      if (response.statusCode == 200) {
        return VerifyGuessResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to verify guess: ${response.statusCode}');
    } catch (e) {
      debugPrint('AnimalsRepository.verifyGuess error: $e');
      rethrow;
    }
  }

  /// Get teaching images for a specific animal
  static Future<TeachingImagesResponse> getTeachingImages(String animal) async {
    try {
      final response = await ApiClient.get('$_basePath/teaching?animal=$animal');
      if (response.statusCode == 200) {
        return TeachingImagesResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to get teaching images: ${response.statusCode}');
    } catch (e) {
      debugPrint('AnimalsRepository.getTeachingImages error: $e');
      rethrow;
    }
  }

  /// Validate user's teaching selections
  static Future<ValidateTeachingResponse> validateTeaching({
    required String targetAnimal,
    required List<String> selectedImageIds,
  }) async {
    try {
      final response = await ApiClient.post('$_basePath/validate-teaching', {
        'target_animal': targetAnimal,
        'selected_image_ids': selectedImageIds,
      });
      if (response.statusCode == 200) {
        return ValidateTeachingResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to validate teaching: ${response.statusCode}');
    } catch (e) {
      debugPrint('AnimalsRepository.validateTeaching error: $e');
      rethrow;
    }
  }

  /// Get current mission progress
  static Future<MissionProgressResponse> getProgress() async {
    try {
      final response = await ApiClient.get('$_basePath/progress');
      if (response.statusCode == 200) {
        return MissionProgressResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to get progress: ${response.statusCode}');
    } catch (e) {
      debugPrint('AnimalsRepository.getProgress error: $e');
      rethrow;
    }
  }

  /// Build full image URL
  static String getImageUrl(String relativePath) {
    return '${AppConfig.apiBaseUrl}$relativePath';
  }
}
