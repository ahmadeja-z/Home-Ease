// import 'dart:convert';
//
// import 'package:flutter/material.dart';
//
// import '../models/user_model.dart';
// import 'localStorage/my-local-controller.dart';
//
//
// class UserService {
//   static saveUserData( UserModel userModel) async {
//     await LocalStorage.saveData(
//         key: "user", value: jsonEncode(userModel.toJson()));
//   }
//
//   static Future<bool> getUser() async {
//     String? userData = await LocalStorage.getData(key: 'user');
//     if (userData != null) {
//       UserModel userModel = UserModel.fromJson(jsonDecode(userData));
//       // await context.read<AuthProvider>().initUser(context, userModel);
//       return true;
//     }
//     return false;
//   }
//
//   static clearUserData() async {
//     await LocalStorage.removeAll();
//   }
// }
