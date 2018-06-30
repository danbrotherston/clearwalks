import 'dart:ui';

import 'package:flutter/material.dart';

class InitialScreen extends StatelessWidget {

  static const String _byline = 'Help us gather data about\nwhen and where sidewalks\nare blocked.';
  static const String _title = 'Clear Walks';
  static const String _followLine = 'Not affiliated or mobilized by TriTAG';

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
                  padding: const EdgeInsets.symmetric(vertical: 120.0, horizontal: 40.0),
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
                child: new Text('Sign in'),
                onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
              ),
              _makeShadow((Color color) => new Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80.0),
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

  Widget _makeShadow(Function child) {
    return new Stack(
      children: <Widget>[
        new Positioned(
            top: 2.0,
            left: 2.0,
            child: child(Colors.black38)
        ),
        new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: child(Colors.white)
        )
      ]
    );
  }
}