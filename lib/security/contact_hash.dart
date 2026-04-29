//======= DART LEVEL CONTACT HASHING UNIT======
import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashNumber(String number) {
  return sha256.convert(utf8.encode(number)).toString();
}
