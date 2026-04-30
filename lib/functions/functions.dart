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
Future<String?> editMail({
  required String phonenumber,
  required String newMail,
  required List<UserDetails> allUsers,
}) async {
  try {
    // 1. UPDATE SERVER
    final response = await api.client.put(updateEmailUrl, data: {
      "phoneNumber": phonenumber,
      "newEmail": newMail,
    });

    if (response.statusCode == 200) {
      // 2. UPDATE LOCAL SQLITE
      bool localSuccess = await updateEmailDataBase(phonenumber, newMail);
      
      if (localSuccess) {
        // Optional: Update global currentUser object so the UI reflects changes immediately
        if (currentUser != null) currentUser!.email = newMail;
        
             await storage.deleteAll(); 
        
        return null;
      }
    }
  } on DioException catch (e) {
    return "Server Email Update Failed: ${e.response?.data['error']}";

  } catch (e) {
    return "Local Sync Error: $e";
  }
  return "Error";
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
Future<String?> updatePassword({
  required String newPassword,
}) async {
  try {
    final token = await getToken();

    final response = await api.client.put(
      updatePasswordUrl,
      data: {
        "newPassword": newPassword,
      },
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
        },
      ),
    );

    if (response.statusCode == 200) {
      bool localSuccess = await updatePassDataBase(
        currentUser!.email,
        newPassword,
      );

      if (localSuccess) {
        await storage.deleteAll(); // force re-login
        return null;
      }
    }
  } on DioException catch (e) {
    return e.response?.data['error'] ?? "Server error";
  }

  return "Error";
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

//________Contact_____Sync______Logic
// Helper for cleaning numbers
String clean(String phone) => phone.replaceAll(RegExp(r'\D'), '');

Future<List<SyncedContact>> getMatchedContacts(BuildContext context) async {
  try {
    await FlutterContacts.requestPermission();
    
    // Fetch only phone numbers to save memory/speed
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    
    // Use a Set to avoid sending the same number multiple times
    Set<String> last10Numbers = {};

    for (var contact in contacts) {
      for (var phone in contact.phones) {
        String cleaned = phone.number.replaceAll(RegExp(r'\D'), '');
        if (cleaned.length >= 10) {
          // Extract only the last 10 digits
          last10Numbers.add(cleaned.substring(cleaned.length - 10));
        }
      }
    }

    if (last10Numbers.isEmpty) return [];

    // Send the list to the server
    final response = await api.client.post(syncContactsUrl, data: {
      "contacts": last10Numbers.toList()
    });

    if (response.statusCode == 200) {
      List data = response.data["matched_users"];
      return data.map<SyncedContact>((json) => SyncedContact(
        id: json["id"].toString(),
        userName: json["userName"],
        phoneNumber: json["phoneNumber"],
        currentUserPhone: currentUser?.phoneNumber ?? "",
      )).toList();
    }
  } catch (e) {
    print("Sync error: $e");
  }
  return [];
}

// Simple helper to see logs on your screen
void _showDebug(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}



//________Search____User____By____Number
Future<SyncedContact?> findUserByNumber(String input) async {
  if (currentUser == null) return null;

  try {
    final response = await api.client.post('$findUserUrl', data: {
      "contacts": [clean(input)]
    });

    if (response.statusCode == 200) {
      List data = response.data["matched_users"];
      if (data.isNotEmpty) {
        var json = data[0];
        
        // FIX 3: Added required parameter
        return SyncedContact(
          id: json["id"].toString(),
          userName: json["userName"],
          phoneNumber: json["phoneNumber"],
          currentUserPhone: currentUser!.phoneNumber, // Added required parameter
        );
      }
    }
  } catch (e) {
    print("Find error: $e");
  }
  return null;
}


//________Create_____Group______Logic
Future<String?> createGroupLogic(String groupName, List<String> memberIds) async {
  try {
    final response = await api.client.post("/onechat/create-group", data: {
      "groupName": groupName,
      "members": memberIds.map((id) => int.parse(id)).toList(), // Backend expects Integers
    });

    if (response.statusCode == 201) {
      return null; // Success
    }
  } on DioException catch (e) {
    return e.response?.data['error'] ?? "Failed to create group";
  }
  return "An error occurred";
}
