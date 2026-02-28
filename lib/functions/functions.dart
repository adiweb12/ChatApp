import 'package:flutter/material.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/screens/editor_page.dart';
import 'package:onechat/screens/login_page.dart';

//________LOGOUT___LOGIC______
Future<void> logOutUser(BuildContext context) async{
    isLoggedIn = false;
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
  try {
    UserDetails foundUser = allUsers.firstWhere(
      (user) => user.email == email && user.password == password,
    );
    currentUser = foundUser;
    isLoggedIn = true;
    return true;
  } catch (e) {
    return false;
  }
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
