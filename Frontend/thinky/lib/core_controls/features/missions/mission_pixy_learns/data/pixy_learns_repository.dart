import 'package:thinky/core_controls/network/base_repository.dart';
import 'package:thinky/core_controls/network/api_endpoints.dart';
import 'package:thinky/core_controls/network/api_exceptions.dart';
import 'package:thinky/shared/models/result.dart';
import '../domain/pixy_learns_models.dart';

/// Repository for Pixy Learns feature
class PixyLearnsRepository extends BaseRepository {
  PixyLearnsRepository(super.storage);

  /// Fetch images to label from API
  Future<Result<List<LearningImage>, ApiException>> getImages() async {
    return get<List<LearningImage>>(
      endpoint: ApiEndpoints.pixyLearnImages,
      parser: (data) {
        final imagesList = data['images'] as List? ?? [];
        return imagesList.map((img) => LearningImage.fromJson(img)).toList();
      },
    );
  }

  /// Submit labels for images
  Future<Result<PixyLearnsResult, ApiException>> submitLabels(
    Map<String, String> labels,
  ) async {
    final labelsList = labels.entries
        .map((e) => {'image_id': e.key, 'label': e.value})
        .toList();

    return post<PixyLearnsResult>(
      endpoint: ApiEndpoints.pixyLearnUpload,
      body: {'labels': labelsList},
      parser: (data) => PixyLearnsResult.fromJson(data),
    );
  }
}
