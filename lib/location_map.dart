import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class LocationMap extends StatefulWidget {
  final Map<String, double> _currentLocation;

  static const Map<String, double> _defaultLocation = {
    'latitude': 43.458186,
    'longitude': -80.5186281
  };

  LocationMap({currentLocation}) : this._currentLocation = currentLocation ?? _defaultLocation;

  @override
  State<StatefulWidget> createState() => new LocationMapState();
}

class LocationMapState extends State<LocationMap> {
  Uint8List mapBytes;

  static const apiKey = 'AIzaSyAInd7jJu_aAaNnPBHpNpZaQyr0sa-upuo';

  @override
  void initState() {
    super.initState();
    _readImage();
  }

  void _readImage() {
    String imageUrl = "https://maps.googleapis.com/maps/api/staticmap?center=${widget._currentLocation["latitude"]},${widget._currentLocation["longitude"]}&zoom=18&size=640x400&key=$apiKey"
    http.readBytes(imageUrl).then((bytes) {
      setState(() {
        mapBytes = bytes;
      });
    });
  }

  @override
  void didUpdateWidget(LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._currentLocation['longitude'] != widget._currentLocation['longitude'] ||
        oldWidget._currentLocation['latitude'] != widget._currentLocation['latitude']) {
      _readImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return mapBytes != null
      ? new Image.memory(mapBytes)
      : new Container();
  }
}