import 'package:flutter/material.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amadeus/bo/UserBO.dart';
import 'package:amadeus/cache/CacheController.dart';
import 'package:amadeus/cache/UserCacheController.dart';
import 'package:amadeus/models/UserModel.dart';
import 'package:amadeus/pages/login_page.dart';

class Logout {
  static void goLogin(BuildContext context) async {
    FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
    String token = await _firebaseMessaging.getToken();
    UserModel user = await UserCacheController.getUserCache(context);

    SharedPreferences _sharedPreferences = await SharedPreferences.getInstance();
    _sharedPreferences.remove("USER_ID_KEY_TOKEN");
    _sharedPreferences.remove("USER_TOKEN");

    if(user != null && token != null) {
      await UserBO().logout(context, user, token);
    }

    CacheController.clearCache(context);

    String initialEmail = _sharedPreferences.get(LoginPageState.emailKey) ?? "";
    String initialHost = _sharedPreferences.get(LoginPageState.hostKey) ?? "";
    String initialPassword = _sharedPreferences.get(LoginPageState.passwordKey) ?? "";
    bool rememberPassword = _sharedPreferences.getBool(LoginPageState.rememberPasswordKey) ?? false;
    Navigator.of(context).pushReplacement(
      new MaterialPageRoute(
        settings: const RouteSettings(name: 'login-page'),
        builder: (context) => new LoginPage(
          initialHost: initialHost,
          initialEmail: initialEmail,
          initialPassword: initialPassword,
          rememberPassword: rememberPassword,
        ),
      )
    );
  }
}