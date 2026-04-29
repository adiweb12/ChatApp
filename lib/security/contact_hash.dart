//======= DART LEVEL CONTACT HASHING UNIT======
import 'dart:convert';
import 'package:crypto/crypto.dart';

String normalizeAndHash(String number) {
  return sha256.convert(utf8.encode(number)).toString();
}
