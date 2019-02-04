import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:clearwalks/initial_screen.dart';
import 'package:clearwalks/home.dart';
import 'package:clearwalks/previous_reports.dart';
import 'package:clearwalks/consts.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();
final Location _location = new Location();

initPlatformState() async {
  try {
    await _location.getLocation();
  } on PlatformException catch (e) {
    if (e.code == 'PERMISSION_DENIED') {
      debugPrint('Permission denied');
    } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
      debugPrint('Permission denied - please ask the user to enable it from the app settings');
    }
  }
}

final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

void main() async {
  await FirebaseDatabase.instance.setPersistenceEnabled(true);

  initPlatformState();

  _firebaseMessaging.requestNotificationPermissions();
  _firebaseMessaging.configure();

  String initialRoute = '/';
  final GoogleSignInAccount googleUser = await _googleSignIn.signInSilently();
  if (googleUser != null) {
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final FirebaseUser user = await _auth.signInWithGoogle(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    if (user != null) {
      initialRoute = '/home';
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String prefsKey = (user.uid + FB_USERS_FCM_TOKEN_PATH);
      try {
        if (prefs.getBool(prefsKey) != true) {
          final String token = await _firebaseMessaging.getToken();
          await FirebaseDatabase
            .instance
            .reference()
            .child(FB_USERS_PATH)
            .child(user.uid)
            .child(FB_USERS_FCM_TOKEN_PATH).set(token);
          prefs.setBool(prefsKey, true);
        }
      } catch(error) {}
    }
  }

  runApp(new MaterialApp(
    title: 'ClearWalks',
    theme: new ThemeData(primarySwatch: Colors.green),
    routes: <String, WidgetBuilder>{
      NAV_ROOT_PATH: (BuildContext context) => new InitialScreen(),
      NAV_HOME_PATH: (BuildContext context) => new Home(),
      NAV_PREV_PATH: (BuildContext context) => new PreviousReports()
    },
    initialRoute: initialRoute,
  ));
}