import 'package:json_annotation/json_annotation.dart';

part 'qobuz_models.g.dart';

@JsonSerializable(createToJson: false)
class QobuzArtist {
  final int id;
  final String name;
  final String? image;
  @JsonKey(name: 'albums_count')
  final int? albumsCount;

  QobuzArtist(this.id, this.name, this.image, this.albumsCount);

  factory QobuzArtist.fromJson(Map<String, dynamic> json) =>
      _$QobuzArtistFromJson(json);
}

@JsonSerializable(createToJson: false)
class QobuzImage {
  final String? small;
  final String? thumbnail;
  final String? large;
  final String? back;

  QobuzImage(this.small, this.thumbnail, this.large, this.back);

  factory QobuzImage.fromJson(Map<String, dynamic> json) =>
      _$QobuzImageFromJson(json);
}

@JsonSerializable(createToJson: false)
class QobuzGenre {
  final int id;
  final String name;

  QobuzGenre(this.id, this.name);

  factory QobuzGenre.fromJson(Map<String, dynamic> json) =>
      _$QobuzGenreFromJson(json);
}

@JsonSerializable(createToJson: false)
class QobuzAlbum {
  final String? id;
  @JsonKey(name: 'qobuz_id')
  final int? qobuzId;
  final String title;
  final String? version;
  final QobuzGenre? genre;
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
    this.artist,
    this.artists,
    this.image,
    this.maximumBitDepth,
    this.maximumSamplingRate,
    this.releasedAt,
    this.duration,
    this.tracksCount,
    this.hires,
    this.streamable,
    this.parentalWarning,
  );

  factory QobuzAlbum.fromJson(Map<String, dynamic> json) =>
      _$QobuzAlbumFromJson(json);

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
  final String? version;
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

  factory QobuzTrack.fromJson(Map<String, dynamic> json) =>
      _$QobuzTrackFromJson(json);
}

@JsonSerializable(createToJson: false)
class SearchResults {
  final String query;
  final AlbumsResult? albums;
  final TracksResult? tracks;

  SearchResults(this.query, this.albums, this.tracks);

  factory SearchResults.fromJson(Map<String, dynamic> json) =>
      _$SearchResultsFromJson(json);
}

@JsonSerializable(createToJson: false)
class AlbumsResult {
  final int limit;
  final int offset;
  final int total;
  final List<QobuzAlbum>? items;

  AlbumsResult(this.limit, this.offset, this.total, this.items);

  factory AlbumsResult.fromJson(Map<String, dynamic> json) =>
      _$AlbumsResultFromJson(json);
}

@JsonSerializable(createToJson: false)
class TracksResult {
  final int limit;
  final int offset;
  final int total;
  final List<QobuzTrack>? items;

  TracksResult(this.limit, this.offset, this.total, this.items);

  factory TracksResult.fromJson(Map<String, dynamic> json) =>
      _$TracksResultFromJson(json);
}

@JsonSerializable(createToJson: false)
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
