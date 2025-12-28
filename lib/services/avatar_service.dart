import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Avatar configuration that can be either a Notion Avatar or a custom photo
class AvatarConfig {
  final String type; // 'notion' or 'custom'
  final int? accessories;
  final int? eyes;
  final int? eyebrows;
  final int? face;
  final int? glasses;
  final int? hair;
  final int? mouth;
  final int? nose;
  final int? details;
  final int? beard;
  final String? customPhotoPath;
  
  AvatarConfig({
    required this.type,
    this.accessories,
    this.eyes,
    this.eyebrows,
    this.face,
    this.glasses,
    this.hair,
    this.mouth,
    this.nose,
    this.details,
    this.beard,
    this.customPhotoPath,
  });
  
  /// Create a Notion Avatar config
  factory AvatarConfig.notion({
    required int accessories,
    required int eyes,
    required int eyebrows,
    required int face,
    required int glasses,
    required int hair,
    required int mouth,
    required int nose,
    required int details,
    required int beard,
  }) {
    return AvatarConfig(
      type: 'notion',
      accessories: accessories,
      eyes: eyes,
      eyebrows: eyebrows,
      face: face,
      glasses: glasses,
      hair: hair,
      mouth: mouth,
      nose: nose,
      details: details,
      beard: beard,
    );
  }
  
  /// Create a custom photo config
  factory AvatarConfig.custom(String photoPath) {
    return AvatarConfig(
      type: 'custom',
      customPhotoPath: photoPath,
    );
  }
  
  /// Create a preset Notion Avatar based on index
  factory AvatarConfig.preset(int index) {
    return AvatarConfig.notion(
      accessories: index * 3 % 10,
      eyes: (index * 2 + 1) % 10,
      eyebrows: (index + 3) % 10,
      face: index % 10,
      glasses: (index * 4) % 10,
      hair: (index * 2) % 10,
      mouth: (index + 2) % 10,
      nose: (index + 1) % 10,
      details: (index * 3 + 1) % 10,
      beard: (index * 5) % 10,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'accessories': accessories,
      'eyes': eyes,
      'eyebrows': eyebrows,
      'face': face,
      'glasses': glasses,
      'hair': hair,
      'mouth': mouth,
      'nose': nose,
      'details': details,
      'beard': beard,
      'customPhotoPath': customPhotoPath,
    };
  }
  
  factory AvatarConfig.fromJson(Map<String, dynamic> json) {
    return AvatarConfig(
      type: json['type'] ?? 'notion',
      accessories: json['accessories'],
      eyes: json['eyes'],
      eyebrows: json['eyebrows'],
      face: json['face'],
      glasses: json['glasses'],
      hair: json['hair'],
      mouth: json['mouth'],
      nose: json['nose'],
      details: json['details'],
      beard: json['beard'],
      customPhotoPath: json['customPhotoPath'],
    );
  }
  
  bool get isCustom => type == 'custom';
  bool get isNotion => type == 'notion';
}

class AvatarService {
  static const String _avatarKey = 'avatar_config';
  
  /// Save avatar configuration
  static Future<void> saveAvatar(AvatarConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, jsonEncode(config.toJson()));
  }
  
  /// Load avatar configuration
  static Future<AvatarConfig> loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_avatarKey);
    
    if (jsonString == null) {
      // Return default preset
      return AvatarConfig.preset(0);
    }
    
    try {
      final json = jsonDecode(jsonString);
      return AvatarConfig.fromJson(json);
    } catch (e) {
      // Handle legacy format (just a seed string)
      final legacySeed = prefs.getString('avatar_seed');
      if (legacySeed != null) {
        final index = int.tryParse(legacySeed.split('_').last) ?? 0;
        return AvatarConfig.preset(index);
      }
      return AvatarConfig.preset(0);
    }
  }
  
  /// Generate a list of preset configurations
  static List<AvatarConfig> getPresets({int count = 12}) {
    return List.generate(count, (index) => AvatarConfig.preset(index));
  }
}
