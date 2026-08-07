import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

/// A standard-compliant metadata tagger for FLAC files written in pure Dart.
///
/// Discards existing VORBIS_COMMENT and PICTURE blocks, writes new Vorbis comments
/// and cover art, and guarantees that the last block has the last-metadata-block flag set.
class FlacTagger {
  static Future<void> writeTags({
    required String filePath,
    required Map<String, String> tags,
    Uint8List? coverBytes,
    String? coverMimeType,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    final input = await file.open(mode: FileMode.read);
    late final List<_MetadataBlock> keptBlocks;
    late final int audioOffset;
    try {
      final signature = await _readExactly(input, 4);
      if (signature[0] != 0x66 ||
          signature[1] != 0x4C ||
          signature[2] != 0x61 ||
          signature[3] != 0x43) {
        throw Exception('Not a valid FLAC file');
      }

      keptBlocks = <_MetadataBlock>[];
      var isLastBlock = false;
      while (!isLastBlock) {
        final header = await _readExactly(input, 4);
        final headerByte = header[0];
        isLastBlock = (headerByte & 0x80) != 0;
        final blockType = headerByte & 0x7F;
        final length = (header[1] << 16) | (header[2] << 8) | header[3];
        final payload = await _readExactly(input, length);

        // Discard existing VORBIS_COMMENT (4) and PICTURE (6) blocks.
        if (blockType != 4 && blockType != 6) {
          keptBlocks.add(_MetadataBlock(type: blockType, payload: payload));
        }
      }
      audioOffset = await input.position();
    } finally {
      await input.close();
    }

    final newBlocks = <_MetadataBlock>[...keptBlocks];
    final commentPayload = _createVorbisCommentPayload(tags);
    newBlocks.add(_MetadataBlock(type: 4, payload: commentPayload));
    if (coverBytes != null && coverBytes.isNotEmpty) {
      final picturePayload = _createPicturePayload(
        coverBytes,
        coverMimeType ?? _detectPictureMime(coverBytes),
      );
      newBlocks.add(_MetadataBlock(type: 6, payload: picturePayload));
    }

    final tempFile = File('${file.path}.tagging');
    try {
      final output = tempFile.openWrite(mode: FileMode.write);
      try {
        output.add(const [0x66, 0x4C, 0x61, 0x43]);
        for (var i = 0; i < newBlocks.length; i++) {
          final block = newBlocks[i];
          var headerByte = block.type;
          if (i == newBlocks.length - 1) {
            headerByte |= 0x80;
          }

          final length = block.payload.length;
          if (length > 0xFFFFFF) {
            throw Exception('FLAC metadata block is too large.');
          }
          output.add([
            headerByte,
            (length >> 16) & 0xFF,
            (length >> 8) & 0xFF,
            length & 0xFF,
          ]);
          output.add(block.payload);
        }
        await output.addStream(file.openRead(audioOffset));
      } finally {
        await output.close();
      }

      try {
        await tempFile.rename(file.path);
      } on FileSystemException {
        await tempFile.copy(file.path);
        await tempFile.delete();
      }
    } catch (_) {
      try {
        if (await tempFile.exists()) await tempFile.delete();
      } catch (_) {}
      rethrow;
    }
  }

  static Future<Uint8List> _readExactly(
    RandomAccessFile file,
    int length,
  ) async {
    final bytes = await file.read(length);
    if (bytes.length != length) {
      throw Exception('Unexpected end of file while reading FLAC metadata.');
    }
    return bytes;
  }

  static Uint8List _createVorbisCommentPayload(Map<String, String> tags) {
    final builder = BytesBuilder();

    // Vendor string length (0)
    builder.add(_intToUint32LE(0));

    // User comments count
    builder.add(_intToUint32LE(tags.length));

    for (final entry in tags.entries) {
      final comment = '${entry.key.toUpperCase()}=${entry.value}';
      final commentBytes = utf8.encode(comment);
      builder.add(_intToUint32LE(commentBytes.length));
      builder.add(commentBytes);
    }

    return builder.toBytes();
  }

  static Uint8List _createPicturePayload(
    Uint8List coverBytes,
    String mimeType,
  ) {
    final builder = BytesBuilder();

    // Picture type: 3 (Front Cover) - 4 bytes big-endian
    builder.add(_intToUint32BE(3));

    final mimeBytes = ascii.encode(mimeType);
    builder.add(_intToUint32BE(mimeBytes.length));
    builder.add(mimeBytes);

    // Description length: 0
    builder.add(_intToUint32BE(0));

    // Width, Height, Depth, Colors (all 0) - 4 * 4 bytes = 16 bytes
    builder.add(_intToUint32BE(0));
    builder.add(_intToUint32BE(0));
    builder.add(_intToUint32BE(0));
    builder.add(_intToUint32BE(0));

    // Picture data length
    builder.add(_intToUint32BE(coverBytes.length));
    builder.add(coverBytes);

    return builder.toBytes();
  }

  static String _detectPictureMime(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 6) {
      final signature = ascii.decode(bytes.sublist(0, 6), allowInvalid: true);
      if (signature == 'GIF87a' || signature == 'GIF89a') return 'image/gif';
    }
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'image/bmp';
    }
    return 'image/jpeg';
  }

  static Uint8List _intToUint32LE(int val) {
    final b = Uint8List(4);
    b[0] = val & 0xFF;
    b[1] = (val >> 8) & 0xFF;
    b[2] = (val >> 16) & 0xFF;
    b[3] = (val >> 24) & 0xFF;
    return b;
  }

  static Uint8List _intToUint32BE(int val) {
    final b = Uint8List(4);
    b[0] = (val >> 24) & 0xFF;
    b[1] = (val >> 16) & 0xFF;
    b[2] = (val >> 8) & 0xFF;
    b[3] = val & 0xFF;
    return b;
  }
}

class _MetadataBlock {
  final int type;
  final Uint8List payload;

  _MetadataBlock({required this.type, required this.payload});
}
