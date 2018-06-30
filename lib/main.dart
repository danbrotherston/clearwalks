import 'package:flutter/material.dart';

import 'package:clearwalks/initial_screen.dart';
import 'package:clearwalks/home.dart';
import 'package:clearwalks/previous_reports.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();

void main() async {
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