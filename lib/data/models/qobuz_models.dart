import 'package:json_annotation/json_annotation.dart';

part 'qobuz_models.g.dart';

String? _nullableStringFromJson(Object? value) {
  if (value is String) return value;
  if (value is Map && value['url'] is String) return value['url'] as String;
  return null;
}

String? _stringFromJson(Object? value) => value is String ? value : null;

int? _intFromJson(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

num? _numFromJson(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '');
}

Map<String, dynamic>? _mapFromJson(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>>? _mapListFromJson(Object? value) {
  if (value is! List) return null;
  return value.map(_mapFromJson).whereType<Map<String, dynamic>>().toList();
}

@JsonSerializable(createToJson: false)
class QobuzArtist {
  final int id;
  final String name;
  @JsonKey(fromJson: _imageUrlFromJson)
  final String? image;
  @JsonKey(name: 'albums_count')
  final int? albumsCount;

  QobuzArtist(this.id, this.name, this.image, this.albumsCount);

  factory QobuzArtist.fromJson(Map<String, dynamic> json) => QobuzArtist(
    _intFromJson(json['id']) ?? 0,
    _stringFromJson(json['name']) ?? '',
    _imageUrlFromJson(json['image']),
    _intFromJson(json['albums_count']),
  );

  static String? _imageUrlFromJson(Object? value) {
    if (value is String) return value;
    if (value is! Map) return null;

    for (final size in ['large', 'medium', 'small', 'thumbnail']) {
      final url = value[size];
      if (url is String && url.isNotEmpty) return url;
    }
    return null;
  }
}

@JsonSerializable(createToJson: false)
class QobuzImage {
  @JsonKey(fromJson: _nullableStringFromJson)
  final String? small;
  @JsonKey(fromJson: _nullableStringFromJson)
  final String? thumbnail;
  @JsonKey(fromJson: _nullableStringFromJson)
  final String? large;
  @JsonKey(fromJson: _nullableStringFromJson)
  final String? back;

  QobuzImage(this.small, this.thumbnail, this.large, this.back);

  factory QobuzImage.fromJson(Map<String, dynamic> json) => QobuzImage(
    _nullableStringFromJson(json['small']),
    _nullableStringFromJson(json['thumbnail']),
    _nullableStringFromJson(json['large']),
    _nullableStringFromJson(json['back']),
  );
}

@JsonSerializable(createToJson: false)
class QobuzGenre {
  final int id;
  final String name;

  QobuzGenre(this.id, this.name);

  factory QobuzGenre.fromJson(Map<String, dynamic> json) => QobuzGenre(
    _intFromJson(json['id']) ?? 0,
    _stringFromJson(json['name']) ?? '',
  );
}

@JsonSerializable(createToJson: false)
class QobuzAlbum {
  @JsonKey(fromJson: _nullableStringFromJson)
  final String? id;
  @JsonKey(name: 'qobuz_id')
  final int? qobuzId;
  final String title;
  @JsonKey(fromJson: _nullableStringFromJson)
  final String? version;
  final QobuzGenre? genre;
  @JsonKey(fromJson: _nullableStringFromJson)
  final String? upc;
  @JsonKey(fromJson: _labelNameFromJson)
  final String? label;
  @JsonKey(fromJson: _nullableStringFromJson)
  final String? copyright;
  final QobuzArtist? artist;
  final List<QobuzArtist>? artists;
  final QobuzImage? image;
  @JsonKey(name: 'maximum_bit_depth')
  final int? maximumBitDepth;
  @JsonKey(name: 'maximum_sampling_rate')
  final num? maximumSamplingRate;
  @JsonKey(name: 'released_at')
  final int? releasedAt;
  final int? duration;
  @JsonKey(name: 'tracks_count')
  final int? tracksCount;
  @JsonKey(name: 'media_count')
  final int? mediaCount;
  final bool? hires;
  final bool? streamable;
  @JsonKey(name: 'parental_warning')
  final bool? parentalWarning;

  QobuzAlbum(
    this.id,
    this.qobuzId,
    this.title,
    this.version,
    this.genre,
    this.upc,
    this.label,
    this.copyright,
    this.artist,
    this.artists,
    this.image,
    this.maximumBitDepth,
    this.maximumSamplingRate,
    this.releasedAt,
    this.duration,
    this.tracksCount,
    this.mediaCount,
    this.hires,
    this.streamable,
    this.parentalWarning,
  );

  factory QobuzAlbum.fromJson(Map<String, dynamic> json) {
    final imageData = _mapFromJson(json['image']);
    final imageUrl = _stringFromJson(json['image']);
    final genreData = _mapFromJson(json['genre']);
    final artistData = _mapFromJson(json['artist']);
    final artistsData = _mapListFromJson(json['artists']);
    return QobuzAlbum(
      _stringFromJson(json['id']),
      _intFromJson(json['qobuz_id']),
      _stringFromJson(json['title']) ?? '',
      _stringFromJson(json['version']),
      genreData == null ? null : QobuzGenre.fromJson(genreData),
      _stringFromJson(json['upc']),
      _labelNameFromJson(json['label']),
      _stringFromJson(json['copyright']),
      artistData == null ? null : QobuzArtist.fromJson(artistData),
      artistsData?.map(QobuzArtist.fromJson).toList(),
      imageData == null
          ? imageUrl == null
                ? null
                : QobuzImage(null, null, imageUrl, null)
          : QobuzImage.fromJson(imageData),
      _intFromJson(json['maximum_bit_depth']),
      _numFromJson(json['maximum_sampling_rate']),
      _intFromJson(json['released_at']),
      _intFromJson(json['duration']),
      _intFromJson(json['tracks_count']),
      _intFromJson(json['media_count']),
      json['hires'] is bool ? json['hires'] as bool : null,
      json['streamable'] is bool ? json['streamable'] as bool : null,
      json['parental_warning'] is bool
          ? json['parental_warning'] as bool
          : null,
    );
  }

  static String? _labelNameFromJson(Object? value) {
    if (value is String) return value;
    if (value is Map && value['name'] is String) {
      return value['name'] as String;
    }
    return null;
  }

  String getCoverLargeUrl() {
    return image?.large ?? '';
  }

  String getFullResImageUrl() {
    final lg = image?.large ?? '';
    if (lg.length > 7) {
      return "${lg.substring(0, lg.length - 7)}org.jpg";
    }
    return lg;
  }
}

@JsonSerializable(createToJson: false)
class QobuzTrack {
  final int id;
  final String title;
  @JsonKey(fromJson: _nullableStringFromJson)
  final String? version;
  @JsonKey(fromJson: _nullableStringFromJson)
  final String? isrc;
  final int? duration;
  @JsonKey(name: 'track_number')
  final int? trackNumber;
  @JsonKey(name: 'media_number')
  final int? mediaNumber;
  @JsonKey(name: 'maximum_bit_depth')
  final int? maximumBitDepth;
  @JsonKey(name: 'maximum_sampling_rate')
  final num? maximumSamplingRate;
  final bool? hires;
  final bool? streamable;
  @JsonKey(name: 'parental_warning')
  final bool? parentalWarning;
  final QobuzAlbum? album;
  final QobuzArtist? performer;

  QobuzTrack(
    this.id,
    this.title,
    this.version,
    this.isrc,
    this.duration,
    this.trackNumber,
    this.mediaNumber,
    this.maximumBitDepth,
    this.maximumSamplingRate,
    this.hires,
    this.streamable,
    this.parentalWarning,
    this.album,
    this.performer,
  );

  factory QobuzTrack.fromJson(Map<String, dynamic> json) {
    final albumData = _mapFromJson(json['album']);
    final performerData = _mapFromJson(json['performer']);
    return QobuzTrack(
      _intFromJson(json['id']) ?? 0,
      _stringFromJson(json['title']) ?? '',
      _stringFromJson(json['version']),
      _stringFromJson(json['isrc']),
      _intFromJson(json['duration']),
      _intFromJson(json['track_number']),
      _intFromJson(json['media_number']),
      _intFromJson(json['maximum_bit_depth']),
      _numFromJson(json['maximum_sampling_rate']),
      json['hires'] is bool ? json['hires'] as bool : null,
      json['streamable'] is bool ? json['streamable'] as bool : null,
      json['parental_warning'] is bool
          ? json['parental_warning'] as bool
          : null,
      albumData == null ? null : QobuzAlbum.fromJson(albumData),
      performerData == null ? null : QobuzArtist.fromJson(performerData),
    );
  }
}

@JsonSerializable(createToJson: false)
class SearchResults {
  final String query;
  final AlbumsResult? albums;
  final TracksResult? tracks;

  SearchResults(this.query, this.albums, this.tracks);

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    final albumsData = _mapFromJson(json['albums']);
    final tracksData = _mapFromJson(json['tracks']);
    return SearchResults(
      _stringFromJson(json['query']) ?? '',
      albumsData == null ? null : AlbumsResult.fromJson(albumsData),
      tracksData == null ? null : TracksResult.fromJson(tracksData),
    );
  }
}

@JsonSerializable(createToJson: false)
class AlbumsResult {
  final int limit;
  final int offset;
  final int total;
  final List<QobuzAlbum>? items;

  AlbumsResult(this.limit, this.offset, this.total, this.items);

  factory AlbumsResult.fromJson(Map<String, dynamic> json) {
    final items = _mapListFromJson(json['items']);
    return AlbumsResult(
      _intFromJson(json['limit']) ?? 0,
      _intFromJson(json['offset']) ?? 0,
      _intFromJson(json['total']) ?? 0,
      items?.map(QobuzAlbum.fromJson).toList(),
    );
  }
}

@JsonSerializable(createToJson: false)
class TracksResult {
  final int limit;
  final int offset;
  final int total;
  final List<QobuzTrack>? items;

  TracksResult(this.limit, this.offset, this.total, this.items);

  factory TracksResult.fromJson(Map<String, dynamic> json) {
    final items = _mapListFromJson(json['items']);
    return TracksResult(
      _intFromJson(json['limit']) ?? 0,
      _intFromJson(json['offset']) ?? 0,
      _intFromJson(json['total']) ?? 0,
      items?.map(QobuzTrack.fromJson).toList(),
    );
  }
}

class FetchedAlbumResponse {
  final QobuzAlbum? album;
  final TracksResult? tracks;

  FetchedAlbumResponse(this.album, this.tracks);

  factory FetchedAlbumResponse.fromJson(Map<String, dynamic> json) {
    // Qobuz album/get endpoint returns album info merged with track info, or sometimes root object is the album.
    return FetchedAlbumResponse(
      QobuzAlbum.fromJson(json),
      json['tracks'] != null ? TracksResult.fromJson(json['tracks']) : null,
    );
  }
}
