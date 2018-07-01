import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:clearwalks/initial_screen.dart';
import 'package:clearwalks/home.dart';
import 'package:clearwalks/previous_reports.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:location/location.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();
final Location _location = new Location();

initPlatformState() async {
  try {
    await _location.getLocation;
  } on PlatformException catch (e) {
    if (e.code == 'PERMISSION_DENIED') {
      debugPrint('Permission denied');
    } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
      debugPrint('Permission denied - please ask the user to enable it from the app settings');
    }
  }
}

void main() async {
  initPlatformState();
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
    }
  }

  runApp(new MaterialApp(
    title: 'ClearWalks',
    theme: new ThemeData(primarySwatch: Colors.green),
    routes: <String, WidgetBuilder>{
      '/': (BuildContext context) => new InitialScreen(),
      '/home': (BuildContext context) => new Home(),
      '/previous': (BuildContext context) => new PreviousReports()
    },
    initialRoute: initialRoute,
  ));
}