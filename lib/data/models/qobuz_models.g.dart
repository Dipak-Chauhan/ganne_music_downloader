// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qobuz_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QobuzArtist _$QobuzArtistFromJson(Map<String, dynamic> json) => QobuzArtist(
  (json['id'] as num).toInt(),
  json['name'] as String,
  json['image'] as String?,
  (json['albums_count'] as num?)?.toInt(),
);

QobuzImage _$QobuzImageFromJson(Map<String, dynamic> json) => QobuzImage(
  json['small'] as String?,
  json['thumbnail'] as String?,
  json['large'] as String?,
  json['back'] as String?,
);

QobuzGenre _$QobuzGenreFromJson(Map<String, dynamic> json) =>
    QobuzGenre((json['id'] as num).toInt(), json['name'] as String);

QobuzAlbum _$QobuzAlbumFromJson(Map<String, dynamic> json) => QobuzAlbum(
  json['id'] as String?,
  (json['qobuz_id'] as num?)?.toInt(),
  json['title'] as String,
  json['version'] as String?,
  json['genre'] == null
      ? null
      : QobuzGenre.fromJson(json['genre'] as Map<String, dynamic>),
  json['artist'] == null
      ? null
      : QobuzArtist.fromJson(json['artist'] as Map<String, dynamic>),
  (json['artists'] as List<dynamic>?)
      ?.map((e) => QobuzArtist.fromJson(e as Map<String, dynamic>))
      .toList(),
  json['image'] == null
      ? null
      : QobuzImage.fromJson(json['image'] as Map<String, dynamic>),
  (json['maximum_bit_depth'] as num?)?.toInt(),
  json['maximum_sampling_rate'] as num?,
  (json['released_at'] as num?)?.toInt(),
  (json['duration'] as num?)?.toInt(),
  (json['tracks_count'] as num?)?.toInt(),
  json['hires'] as bool?,
  json['streamable'] as bool?,
  json['parental_warning'] as bool?,
);

QobuzTrack _$QobuzTrackFromJson(Map<String, dynamic> json) => QobuzTrack(
  (json['id'] as num).toInt(),
  json['title'] as String,
  json['version'] as String?,
  (json['duration'] as num?)?.toInt(),
  (json['track_number'] as num?)?.toInt(),
  (json['media_number'] as num?)?.toInt(),
  (json['maximum_bit_depth'] as num?)?.toInt(),
  json['maximum_sampling_rate'] as num?,
  json['hires'] as bool?,
  json['streamable'] as bool?,
  json['parental_warning'] as bool?,
  json['album'] == null
      ? null
      : QobuzAlbum.fromJson(json['album'] as Map<String, dynamic>),
  json['performer'] == null
      ? null
      : QobuzArtist.fromJson(json['performer'] as Map<String, dynamic>),
);

SearchResults _$SearchResultsFromJson(Map<String, dynamic> json) =>
    SearchResults(
      json['query'] as String,
      json['albums'] == null
          ? null
          : AlbumsResult.fromJson(json['albums'] as Map<String, dynamic>),
      json['tracks'] == null
          ? null
          : TracksResult.fromJson(json['tracks'] as Map<String, dynamic>),
    );

AlbumsResult _$AlbumsResultFromJson(Map<String, dynamic> json) => AlbumsResult(
  (json['limit'] as num).toInt(),
  (json['offset'] as num).toInt(),
  (json['total'] as num).toInt(),
  (json['items'] as List<dynamic>?)
      ?.map((e) => QobuzAlbum.fromJson(e as Map<String, dynamic>))
      .toList(),
);

TracksResult _$TracksResultFromJson(Map<String, dynamic> json) => TracksResult(
  (json['limit'] as num).toInt(),
  (json['offset'] as num).toInt(),
  (json['total'] as num).toInt(),
  (json['items'] as List<dynamic>?)
      ?.map((e) => QobuzTrack.fromJson(e as Map<String, dynamic>))
      .toList(),
);

FetchedAlbumResponse _$FetchedAlbumResponseFromJson(
  Map<String, dynamic> json,
) => FetchedAlbumResponse(
  json['album'] == null
      ? null
      : QobuzAlbum.fromJson(json['album'] as Map<String, dynamic>),
  json['tracks'] == null
      ? null
      : TracksResult.fromJson(json['tracks'] as Map<String, dynamic>),
);
