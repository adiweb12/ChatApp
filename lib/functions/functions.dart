import 'package:flutter/material.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/screens/editor_page.dart';
import 'package:onechat/screens/login_page.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:onechat/constant/constants.dart';
import 'package:onechat/database/operations/database_operation.dart';
import 'package:onechat/database/database_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


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
    if(username==null||username.isEmpty||email==null||email.isEmpty||phonenumber==null||phonenumber.isEmpty||dob==null||dob.isEmpty||password==null||password.isEmpty){
        return false;
    }else if(username.length<3||email.length<7||phonenumber.length<10||dob.length<7||password.length<4){
        return false;
    }else{
    try{
        UserDetails newUser = UserDetails(
            id:DateTime.now().millisecondsSinceEpoch.toString(),
            userName:username,
            phoneNumber:phonenumber,
            email: email,
      password: password,
      dob: dob,
      );
       // allUsers.add(newUser);
      if(await insertUser(newUser)){
      return true;
      }else{
          return false;
      }
    }catch(e){
        return false;
    }
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
Future<bool> loginLogic({
  required String email,
  required String password,
  required List<UserDetails> allUsers,
}) async {
    if(email==null||password==null){
        return false;
    }else if(email.length<=7 || password.length<5){
        return false;
    }else{
  try {
  //  UserDetails foundUser = allUsers.firstWhere(
      //(user) => user.email == email && user.password == password,
      UserDetails? foundUser = await getUser(email, password);
    if(foundUser != null){;
    //flutter_secure_storage
    await storage.write(key: SECRET_LOGIN_KEY,value: 'true');
    await storage.write(key: User_Id,value: foundUser.id);
    
    return true;
    }
    return false;
  } catch (e) {
    return false;
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
