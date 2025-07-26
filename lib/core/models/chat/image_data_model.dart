import 'package:hive_ce/hive.dart';

class ImageData extends HiveObject {
  final String id;

  final String name;

  final String path;

  final int size;

  final String extension;

  ImageData({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.extension,
  });

  /// Creates an ImageData instance from a JSON map.
  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      size: json['size'] as int,
      extension: json['extension'] as String,
    );
  }

  /// Creates a copy of this ImageData but with the given fields replaced with the new values.
  ImageData copyWith({String? id, String? name, String? path, int? size, String? extension}) {
    return ImageData(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      extension: extension ?? this.extension,
    );
  }

  /// Converts this ImageData instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'path': path, 'size': size, 'extension': extension};
  }
}
