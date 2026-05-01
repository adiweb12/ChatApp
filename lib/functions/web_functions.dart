import 'package:flutter/material.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/screens/editor_page.dart';
import 'package:onechat/screens/login_page.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:onechat/constant/constants.dart';
import 'package:onechat/database/operations/database_operation.dart';
import 'package:onechat/database/database_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onechat/backend/api_services.dart';
import 'package:dio/dio.dart';
import 'package:onechat/constant/api_urls.dart';
import 'package:onechat/security/contact_hash.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:onechat/backend/ws_services.dart';

Future<void> chatLoader() async {
  if (currentUser == null) return;

  WSService().connect(currentUser!.phoneNumber);
}
