import 'package:flutter/material.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/screens/editor_page.dart';

Future<bool> editMail({
  required String phonenumber,
  required String newMail,
  required List<UserDetails> allUsers,
}) async {
  try {
    UserDetails userToEdit = allUsers.firstWhere(
      (user) => user.phoneNumber == phonenumber,
    );
    userToEdit.email = newMail;
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> loginLogic({
  required String email,
  required String password,
  required List<UserDetails> allUsers,
}) async {
  try {
    allUsers.firstWhere(
      (user) => user.email == email && user.password == password,
    );
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> updatePassword({
  required String email,
  required String newPassword,
  required List<UserDetails> allUsers,
}) async {
  try {
    UserDetails userToEdit = allUsers.firstWhere(
      (user) => user.email == email,
    );
    userToEdit.password = newPassword;
    return true;
  } catch (e) {
    return false;
  }
}

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
  }
}
