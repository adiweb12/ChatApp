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
import 'package:constant/api_urls.dart';


//________LOGOUT___LOGIC______
Future<void> logOutUser(BuildContext context) async{
    //isLoggedIn = false;
    await storage.deleteAll();
    Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false,
    );
}

//_________Signup___logic_____
Future<bool> signupLogic({
    required String username,
    required String email,
    required String phonenumber,
    required String dob,
    required String password,
    required List<UserDetails> allUsers
}) async{
    try {
    // 1. SERVER SIGNUP
    final response = await api.client.post("$signupBaseUrl", data: {
      "userName": username,
      "email": email,
      "phoneNumber": phonenumber,
      "dob": dob,
      "password": password,
    });

    if (response.statusCode == 201) {
      // 2. STORE LOCALLY SO USER CAN LOGIN OFFLINE LATER
      UserDetails newUser = UserDetails(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID until login
        userName: username,
        email: email,
        phoneNumber: phonenumber,
        password: password,
        dob: dob,
      );
      await insertUser(newUser);
      return true;
    }
  } catch (e) {
    return false;
  }
  return false;
}

//__________mail______edit____logic___
Future<bool> editMail({
  required String phonenumber,
  required String newMail,
  required List<UserDetails> allUsers,
}) async {
  try {
    // Check if the update was successful (returns true/false)
    bool isUpdated = await updateEmailDataBase(phonenumber, newMail);
    
    if (isUpdated) {
      // Clear preferences so user has to log in again with new mail
      final _sharedPref = await SharedPreferences.getInstance();
      await _sharedPref.clear();
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}


//________login_______logic_______
//________login_______logic_______
Future<bool> loginLogic({
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
      final data = response.data; // Added this
      final userData = data["user"]; // Added this

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
      return true;
    }
  } on DioException catch (e) { // Fixed parenthesis error
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return false;
      }
    }
  }
  return false;
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
      final _sharedPref = await SharedPreferences.getInstance();
      await _sharedPref.clear();
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EditMailPage()),
      );
      break;
    case 'editPass':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EditPassPage()),
      );
      break;
          case 'logOut':
            logOutUser(context);
      break;
  }
}

//________Contact_____loading______logic
Future<List<UserDetails>> getMatchedContacts(List<UserDetails> allUsers) async {
  if (await FlutterContacts.requestPermission()) {
    // Fixed: 'Contact' type (not Contacts)
    List<Contact> _phoneContacts = await FlutterContacts.getContacts(withProperties: true);
    List<UserDetails> matchedUsers = [];

    for (var contact in _phoneContacts) { // Fixed: plural s
      for (var phone in contact.phones) {
        String _cleanNumber = phone.number.replaceAll(RegExp(r'\D'), '');

        for (var user in allUsers) {
          String _userCleanNumber = user.phoneNumber.replaceAll(RegExp(r'\D'), '');

          if (_userCleanNumber == _cleanNumber) {

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
