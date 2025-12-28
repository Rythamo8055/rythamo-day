import 'package:image_picker/image_picker.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    return image?.path;
  }

  Future<String?> pickVideo(ImageSource source) async {
    final XFile? video = await _picker.pickVideo(source: source);
    return video?.path;
  }

  void dispose() {
    // No resources to dispose
  }
}
