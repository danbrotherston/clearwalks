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
    String imageUrl = "https://maps.googleapis.com/maps/api/staticmap?center=${widget._currentLocation["latitude"]},${widget._currentLocation["longitude"]}&zoom=18&size=640x400&key=$apiKey";
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
    return mapBytes == null
      ? new Container()
      : new Stack(
        children: <Widget>[
          new Center(child: new Image.memory(mapBytes)),
          new Center(
            child: new Padding(  // Padding ensures the tip of the pointer is at the centre of te map
              padding: const EdgeInsets.only(bottom: 48.0),
              child: Image.asset('assets/map_pin.png', height: 48.0)
            )
          ),
          new Positioned(
            child: new GPSGauge(strength: GPSStrength.WeakSignal),
            top: 8.0,
            right: 8.0,
          )
        ]
      );
  }
}

enum GPSStrength {
  NoTracking,
  NoSignal,
  WeakSignal,
  MediumSignal,
  StrongSignal
}

class GPSGauge extends StatelessWidget {
  final GPSStrength strength;

  GPSGauge({this.strength});

  static const String _noTracking = 'Manually respositioning map.';
  static const String _tracking = 'GPS Signal Strength.';

  static const Color _noSignal = Colors.grey;
  static const Color _weakSignal = Colors.red;
  static const Color _mediumSignal = Colors.orange;
  static const Color _strongSignal = Colors.green;

  @override
  Widget build(BuildContext context) {
    Color color1 = _noSignal, color2 = _noSignal, color3 = _noSignal;
    switch (strength) {
      case GPSStrength.NoSignal:
      case GPSStrength.NoTracking:
        break;

      case GPSStrength.StrongSignal:
        color3 = _strongSignal;
        continue medium;

      medium:
      case GPSStrength.MediumSignal:
        color2 = _mediumSignal;
        continue weak;

      weak:
      case GPSStrength.WeakSignal:
        color1 = _weakSignal;
        break;

      default:
        break;
    }

    const double spacing = 4.0;
    const double boxHeight = 12.0;
    const double boxWidth = 6.0;

    return new ConstrainedBox(
      constraints: new BoxConstraints(maxWidth: 200.0),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.only(bottom: spacing),
            child: new Text(
              strength == GPSStrength.NoTracking ? _noTracking : _tracking,
              style: Theme.of(context).textTheme.body1.copyWith(fontSize: 10.0, color: Colors.black87),
              textAlign: TextAlign.right,
            )
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              new Padding(
                padding: const EdgeInsets.only(right: spacing),
                child: Container(height: boxHeight, width: boxWidth, color: color3)
              ),
              new Padding(
                padding: const EdgeInsets.only(right: spacing),
                child: Container(height: boxHeight, width: boxWidth, color: color2)
              ),
              new Padding(
                padding: const EdgeInsets.only(right: spacing),
                child: Container(height: boxHeight, width: boxWidth, color: color1)
              )
            ],
          )
        ]
      )
    );
  }
}