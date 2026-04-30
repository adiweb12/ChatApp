//======= DART LEVEL CONTACT HASHING UNIT======
import 'dart:convert';
import 'package:crypto/crypto.dart';

String normalizeAndHash(String phoneNumber) {
  // 1. Strip everything except digits (must match the server logic!)
  String clean = phoneNumber.replaceAll(RegExp(r'\D'), '');
  
  // 2. SHA-256
  var bytes = utf8.encode(clean); 
  var digest = sha256.convert(bytes);
  
  // 3. Convert to Hex String
  return digest.toString(); 
}

