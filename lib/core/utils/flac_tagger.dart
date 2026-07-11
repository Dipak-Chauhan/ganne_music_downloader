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
  }) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    if (bytes.length < 4 ||
        bytes[0] != 0x66 ||
        bytes[1] != 0x4C ||
        bytes[2] != 0x61 ||
        bytes[3] != 0x43) {
      throw Exception('Not a valid FLAC file');
    }

    final keptBlocks = <_MetadataBlock>[];
    int offset = 4;

    bool isLastBlock = false;
    while (!isLastBlock && offset < bytes.length) {
      if (offset + 4 > bytes.length) {
        throw Exception('Unexpected end of file while reading metadata headers');
      }

      final headerByte = bytes[offset];
      isLastBlock = (headerByte & 0x80) != 0;
      final blockType = headerByte & 0x7F;

      final length = (bytes[offset + 1] << 16) |
                     (bytes[offset + 2] << 8) |
                     bytes[offset + 3];

      offset += 4;

      if (offset + length > bytes.length) {
        throw Exception('Unexpected end of file while reading metadata payload');
      }

      final payload = bytes.sublist(offset, offset + length);
      offset += length;

      // Discard existing VORBIS_COMMENT (4) and PICTURE (6) blocks
      if (blockType != 4 && blockType != 6) {
        keptBlocks.add(_MetadataBlock(type: blockType, payload: payload));
      }
    }

    final audioData = bytes.sublist(offset);

    // Construct the new list of metadata blocks
    final newBlocks = <_MetadataBlock>[...keptBlocks];

    // Create Vorbis Comment block
    final commentPayload = _createVorbisCommentPayload(tags);
    newBlocks.add(_MetadataBlock(type: 4, payload: commentPayload));

    // Create Picture block if coverBytes is provided
    if (coverBytes != null && coverBytes.isNotEmpty) {
      final picturePayload = _createPicturePayload(coverBytes);
      newBlocks.add(_MetadataBlock(type: 6, payload: picturePayload));
    }

    // Build the final bytes
    final builder = BytesBuilder();
    builder.add(Uint8List.fromList([0x66, 0x4C, 0x61, 0x43])); // 'fLaC'

    for (int i = 0; i < newBlocks.length; i++) {
      final block = newBlocks[i];
      final isLast = (i == newBlocks.length - 1);

      // Header byte: MSB is isLast, lower 7 bits is blockType
      int headerByte = block.type;
      if (isLast) {
        headerByte |= 0x80;
      }

      builder.addByte(headerByte);

      // Length: 24-bit big-endian
      final len = block.payload.length;
      builder.addByte((len >> 16) & 0xFF);
      builder.addByte((len >> 8) & 0xFF);
      builder.addByte(len & 0xFF);

      builder.add(block.payload);
    }

    builder.add(audioData);

    await file.writeAsBytes(builder.toBytes());
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

  static Uint8List _createPicturePayload(Uint8List coverBytes) {
    final builder = BytesBuilder();

    // Picture type: 3 (Front Cover) - 4 bytes big-endian
    builder.add(_intToUint32BE(3));

    // MIME type: "image/jpeg"
    final mimeStr = 'image/jpeg';
    final mimeBytes = ascii.encode(mimeStr);
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
