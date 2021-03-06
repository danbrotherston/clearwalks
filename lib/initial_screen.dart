import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:clearwalks/consts.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();

class InitialScreen extends StatelessWidget {

  static const String _byline = 'Help us gather data about\nwhen and where sidewalks\nare blocked.';
  static const String _title = 'Clear Walks';
  static const String _followLine = 'Author not affiliated or mobilized by TriTAG';

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(_title),
        leading: new Container() // Empty container removes back button.
      ),
      body: new Container(
        constraints: new BoxConstraints.expand(),
        decoration: new BoxDecoration(
          image: new DecorationImage(fit: BoxFit.fill, image: new AssetImage('assets/snowy_sidewalk.jpg'))
        ),
        child: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _makeShadow((Color color) => new Text(
                  _title,
                  style: Theme.of(context).textTheme.headline.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    fontSize: 50.0
                  )
                )
              ),
              _makeShadow((Color color) => new Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 20.0),
                  child: new Text(
                    _byline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold
                    )
                  )
                )
              ),
              new RaisedButton(
                child: new Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Text('Sign in with'),
                    new Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Image(
                        width: 20.0,
                        height: 20.0,
                        fit: BoxFit.scaleDown,
                        image: new AssetImage('assets/google_logo.png')
                      )
                    )
                  ]
                ),
                onPressed: () => _signIn(context),
              ),
              _makeShadow((Color color) => new Padding(
                  padding: const EdgeInsets.only(top: 80.0),
                  child: new Text(
                    _followLine,
                    style: Theme.of(context).textTheme.subhead.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold
                    )
                  )
                )
              )
            ]
          )
        )
      )
    );
  }

  void _signIn(BuildContext context) async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final FirebaseUser user = await _auth.signInWithGoogle(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    assert(user.email != null);
    assert(user.displayName != null);
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);


    final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
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

    Navigator.of(context).pushReplacementNamed(NAV_HOME_PATH);
  }

  Widget _makeShadow(Function child) {
    return new Stack(
      children: <Widget>[
        new Positioned(
            top: 2.0,
            left: 2.0,
            child: child(Colors.black38)
        ),
        new BackdropFilter(
          filter: new ui.ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: child(Colors.white)
        )
      ]
    );
  }
}