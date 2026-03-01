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

//________LOGOUT___LOGIC______
Future<void> logOutUser(BuildContext context) async {
  await storage.deleteAll();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false,
  );
}

//_________Signup___logic_____
Future<String?> signupLogic({
  required String username,
  required String email,
  required String phonenumber,
  required String dob,
  required String password,
  required List<UserDetails> allUsers,
}) async {
  try {
    final response = await api.client.post(signupBaseUrl, data: {
      "userName": username,
      "email": email,
      "phoneNumber": phonenumber,
      "dob": dob,
      "password": password,
    });

    if (response.statusCode == 201) {
      UserDetails newUser = UserDetails(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userName: username,
        email: email,
        phoneNumber: phonenumber,
        password: password,
        dob: dob,
      );
      await insertUser(newUser);
      return null;
    }
  } on DioException catch (e) {
    if (e.response != null && e.response?.data != null) {
      // Return the specific error message from Flask
      return e.response?.data["error"] ?? "Authentication failed ☹️";
    }
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return "Connection to Onechat Brain  failed 😱";
    }
  }
  return "An unexpected fever occurred 🤧";
}

//__________mail______edit____logic___
Future<bool> editMail({
  required String phonenumber,
  required String newMail,
  required List<UserDetails> allUsers,
}) async {
  try {
    bool isUpdated = await updateEmailDataBase(phonenumber, newMail);
    if (isUpdated) {
      await storage.deleteAll();
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

//________login_______logic_______
Future<String?> loginLogic({
  required String email,
  required String password,
  required List<UserDetails> allUsers,
}) async {
  try {
    final response = await api.client.post(loginBaseUrl, data: {
      "email": email,
      "password": password,
    });

    if (response.statusCode == 200) {
      final data = response.data;
      final userData = data["user"];

      await storage.write(key: "access_token", value: data["access_token"]);
      await storage.write(key: "refresh_token", value: data["refresh_token"]);
      await storage.write(key: SECRET_LOGIN_KEY, value: 'true');
      await storage.write(key: User_Id, value: userData["id"].toString());

      UserDetails userToSync = UserDetails(
        id: userData["id"].toString(),
        userName: userData["userName"],
        email: userData["email"],
        phoneNumber: userData["phoneNumber"] ?? "0000000000",
        password: password,
        dob: userData["dob"] ?? "Not Provided",
      );

      await insertUser(userToSync);
      currentUser = userToSync;
      return null; // Success
    }
  } on DioException catch (e) {
    if (e.response != null && e.response?.data != null) {
      // Return the specific error message from Flask
      return e.response?.data["error"] ?? "Authentication failed";
    }
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return "Connection to server failed";
    }
  }
  return "An unexpected error occurred";
}

//______update__password____logic____
Future<bool> updatePassword({
  required String email,
  required String newPassword,
  required List<UserDetails> allUsers,
}) async {
  try {
    bool isUpdated = await updatePassDataBase(email, newPassword);
    if (isUpdated) {
      await storage.deleteAll();
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

//______dropDown_____logic___
Future<void> dropDownLogic(String value, BuildContext context) async {
  switch (value) {
    case 'editMail':
      Navigator.push(context, MaterialPageRoute(builder: (context) => const EditMailPage()));
      break;
    case 'editPass':
      Navigator.push(context, MaterialPageRoute(builder: (context) => const EditPassPage()));
      break;
    case 'logOut':
      logOutUser(context);
      break;
  }
}

//________Contact_____loading______logic
Future<List<UserDetails>> getMatchedContacts(List<UserDetails> allUsers) async {
  if (await FlutterContacts.requestPermission()) {
    List<Contact> phoneContacts = await FlutterContacts.getContacts(withProperties: true);
    List<UserDetails> matchedUsers = [];

    for (var contact in phoneContacts) {
      for (var phone in contact.phones) {
        String cleanNumber = phone.number.replaceAll(RegExp(r'\D'), '');
        for (var user in allUsers) {
          String userCleanNumber = user.phoneNumber.replaceAll(RegExp(r'\D'), '');
          if (userCleanNumber == cleanNumber) {
            if (!matchedUsers.contains(user)) {
              matchedUsers.add(user);
            }
          }
        }
      }
    }
    return matchedUsers;
  } else {
    return [];
  }
}
