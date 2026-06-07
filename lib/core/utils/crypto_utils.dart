import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  static String generateMd5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  static String generateSignature({
    required int trackId,
    required String qualityId,
    required int timestamp,
    required String appSecret,
  }) {
    final rawString =
        'trackgetFileUrlformat_id${qualityId}intentstreamtrack_id$trackId$timestamp$appSecret';
    return generateMd5(rawString);
  }
}
