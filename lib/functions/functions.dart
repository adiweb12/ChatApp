import 'package:flutter/material.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/screens/editor_page.dart';
import 'package:onechat/screens/login_page.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onechat/constant/constants.dart';

//________LOGOUT___LOGIC______
Future<void> logOutUser(BuildContext context) async{
    //isLoggedIn = false;
    final _sharedPref = await SharedPreferences.getInstance();
    await _sharedPref.clear();
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
    }else if(username.length<3||email.length<7||phonenumber.length<10||dob.length<7||password.length<4||){
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
        allUsers.add(newUser);
      return true;
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
    if(currentUser !=null && currentUser!.phoneNumber == phonenumber){
    currentUser!.email = newMail;
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
    UserDetails foundUser = allUsers.firstWhere(
      (user) => user.email == email && user.password == password,
    );
    currentUser = foundUser;
    //SharedPreferences
    final _sharedPref = await SharedPreferences.getInstance(),
    await _sharedPref.setBool(UserLoginInfo,true);
    await _sharedPref.setString(User_Id,foundUser.id)
    //isLoggedIn = true;
    return true;
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
    if(currentUser != null && currentUser!.email==email){
    currentUser!.password = newPassword;
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
            // Logic Fix: Use !matchedUsers.contains to avoid duplicates
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
