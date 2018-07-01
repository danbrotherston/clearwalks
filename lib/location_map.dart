import 'package:flutter/material.dart';

class LocationMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new AspectRatio(
      aspectRatio: 1.33,
      child: new Container(
        constraints: new BoxConstraints.expand(),
        decoration: new BoxDecoration(
          image: new DecorationImage(fit: BoxFit.fill, image: new AssetImage('assets/map_placeholder.png'))
        )
      )
    );
  }
}