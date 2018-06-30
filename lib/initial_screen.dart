import 'package:flutter/material.dart';

class InitialScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Clear Walks'),
        leading: new Container() // Empty container removes back button.
      ),
      body: new Center(
        child: new FlatButton(
          child: new Text('Sign in'),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
        )
      )
    );
  }
}