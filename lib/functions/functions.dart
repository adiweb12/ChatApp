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
  required String email,
  required String newPassword,
  required List<UserDetails> allUsers,
}) async {
  try {
    // 1. UPDATE SERVER
    final response = await api.client.put(updatePasswordUrl, data: {
      "email": email,
      "newPassword": newPassword,
    });

    if (response.statusCode == 200) {
      // 2. UPDATE LOCAL SQLITE
      bool localSuccess = await updatePassDataBase(email, newPassword);
      
      if (localSuccess) {
        // Since password changed, it's safer to clear session and make them re-login
        await storage.deleteAll(); 
        return null;
      }
    }
  } on DioException catch (e) {
     return "Server Password Update Failed: ${e.response?.data['error']}";
  } catch (e) {
     return "Local Sync Error: $e";
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
Future<List<SyncedContact>> getMatchedContacts() async {
  if (currentUser == null) return [];

  // 🔹 Normalize function (OUTSIDE loop)
  String normalize(String number) {
    String clean = number.replaceAll(RegExp(r'\D'), '');

    // India default (+91)
    if (clean.length == 10) {
      return "+91$clean";
    } else if (clean.length > 10) {
      return "+$clean";
    }

    return clean;
  }

  if (await FlutterContacts.requestPermission()) {
    List<Contact> phoneContacts =
        await FlutterContacts.getContacts(withProperties: true);

    Set<String> normalizedNumbers = {};

    // 🔹 Extract + normalize numbers
    for (var contact in phoneContacts) {
      for (var phone in contact.phones) {
        String normalized = normalize(phone.number);

        if (normalized.isNotEmpty) {
          normalizedNumbers.add(normalized);
        }
      }
    }

    try {
      // 🔹 Hash numbers before sending
      final hashedContacts = normalizedNumbers
          .map((num) => hashNumber(num))
          .toList();

      final response = await api.client.post(
        syncContactsUrl,
        data: {
          "contacts": hashedContacts,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data["matched_users"];

        List<SyncedContact> syncedList = [];

        for (var json in data) {
          SyncedContact contact = SyncedContact(
            id: json["id"].toString(),
            currentUserPhone: currentUser!.phoneNumber,
            userName: json["userName"],
            phoneNumber: json["phoneNumber"],
          );

          // 🔹 Save locally (offline support)
          await insertSyncedContact(contact);
          syncedList.add(contact);
        }

        return syncedList;
      }
    } catch (e) {
      print("Sync failed, loading local: $e");
    }
  }

  // 🔹 Fallback to local DB
  return await getLocalSyncedContacts(currentUser!.phoneNumber);
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

//________Search____User____By____Number
Future<SyncedContact?> findUserByNumber(String phoneNumber) async {
  if (currentUser == null) return null;
  
  // Clean the number
  String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

  try {
    final response = await api.client.post(syncContactsUrl, data: {
      "contacts": [cleanNumber], // Send as a list with one item
    });

    if (response.statusCode == 200) {
      List<dynamic> data = response.data["matched_users"];
      if (data.isNotEmpty) {
        var json = data[0];
        SyncedContact newContact = SyncedContact(
          id: json["id"].toString(),
          currentUserPhone: currentUser!.phoneNumber,
          userName: json["userName"],
          phoneNumber: json["phoneNumber"],
        );

        // Save to local SQLite so they appear in the contact list later
        await insertSyncedContact(newContact);
        return newContact;
      }
    }
  } catch (e) {
    print("Search Error: $e");
  }
  return null; // User not found or error
}
