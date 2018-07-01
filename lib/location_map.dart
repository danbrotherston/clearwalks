import 'package:flutter/material.dart';

class LocationMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container(
        constraints: new BoxConstraints.expand(),
        decoration: new BoxDecoration(
          image: new DecorationImage(fit: BoxFit.fill, image: new AssetImage('assets/map_placeholder.png'))
        )
    );
  }
}