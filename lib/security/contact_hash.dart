//======= DART LEVEL CONTACT HASHING UNIT======
import 'dart:convert';
import 'package:crypto/crypto.dart';

String normalizeAndHash(String phoneNumber) {
  // 1. Clean the number (remove spaces, dashes, etc.)
  String clean = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
  
  // 2. SHA-256 Hash
  var bytes = utf8.encode(clean); 
  var digest = sha256.convert(bytes);
  
  // 3. Return as Hex string (matching Node's .digest("hex"))
  return digest.toString(); 
}

