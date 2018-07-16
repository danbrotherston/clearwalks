import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:clearwalks/location_map.dart';
import 'package:clearwalks/address_field.dart';
import 'package:clearwalks/snow_bylaw.dart';

import 'package:firebase_database/firebase_database.dart';

import 'package:location/location.dart';
import 'package:vector_math/vector_math.dart' as VMath;

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new HomeState();
}

enum ProblemLocation {
  Sidewalk,
  CurbCut
}

enum Coverage {
  Slippery,
  Snow,
  SnowBank
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  // User parameters
  bool _submitBylawComplaint = true;
  double _numberOfAffectedSidewalks = 1.0;
  ProblemLocation _locationOfProblem = ProblemLocation.Sidewalk;
  Coverage _typeOfProblem = Coverage.Snow;

  // Location services
  Map<String, double> _currentLocation;
  Map<String, double> _lastGPSLocation;
  StreamSubscription<Map<String, double>> _locationSubscription;
  bool _isManuallyRepositioningMap = false;

  final Location _locationService = new Location();

  double _metersBetween(lat1, long1, lat2, long2) {
    // Derived from the haversine formula as described here: https://www.movable-type.co.uk/scripts/latlong.html
    double radius = 6371000.0;
    double radLat1 = VMath.radians(lat1);
    double radLat2 = VMath.radians(lat2);
    double deltaLat = VMath.radians(lat1-lat2);
    double deltaLong = VMath.radians(long1-long2);

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
               cos(radLat1) * cos(radLat2) * sin(deltaLong / 2) * sin(deltaLong / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = radius * c;

    return distance.abs();
  }

  @override
  void initState() {
    super.initState();
    _locationSubscription =
      _locationService.onLocationChanged.listen((Map<String,double> result) {
        _lastGPSLocation = result;
        double minDistanceForMapUpdate = 20.0;
        double distance = _currentLocation == null
          ? double.infinity
          : _metersBetween(
            _currentLocation['latitude'],
            _currentLocation['longitude'],
            result['latitude'],
            result['longitude']);

        if (!_isManuallyRepositioningMap && distance > minDistanceForMapUpdate) {
          setState(() {
            _currentLocation = result;
          });
        }
      });
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Clear Walks'),
        leading: new IconButton(
          icon: new Icon(Icons.list),
          onPressed: () => Navigator.of(context).pushNamed('/previous')
        ),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.add),
            onPressed: _submitReport,
          )
        ],
      ),
      /*floatingActionButton: new FloatingActionButton(
        tooltip: 'Submit this sidewalk report.',
        child: new Icon(Icons.add),
        onPressed: _submitReport,
      ),*/
      body: new Column(
        children: <Widget>[
          new SnowBylawWidget(helpIcon: _helpIcon(_bylawHelpTitle, _bylawHelpText)),
          _bylawComplaint(),
          new Divider(height: 2.0)
        ]
        ..addAll(_snowCoverage())
        ..addAll(_snowLocation())
        ..add(_sidewalksAffected())
        ..add(
          new Expanded(
            child: new LocationMap(
              currentLocation: _currentLocation,
              onPanStart: () => _isManuallyRepositioningMap = true,
              onPanEnd: (Offset newOffset) {
                if (_currentLocation == null) return;

                int zoom = (1 << 17);
                double size = 256.0 * zoom;
                double resLat = cos(_currentLocation['latitude'] * pi / 180.0) * 360.0 / size;
                double resLong = 360 / size;

                double deltaLat = resLat * newOffset.dy;
                double deltaLong = resLong * newOffset.dx * -1;

                var newLocation = {
                  'latitude': _currentLocation['latitude'] + deltaLat,
                  'longitude': _currentLocation['longitude'] + deltaLong
                };

                setState(() => _currentLocation = newLocation);
              },
              onTapGPSMode: () => setState(() {
                _isManuallyRepositioningMap = false;
                _currentLocation = _lastGPSLocation;
              }),
            )
          )
        )
        ..add(new Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: new AddressField(currentLocation: _currentLocation)
        ))
      )
    );
  }

  Widget _helpIcon(String helpTitle, String helpText) {
    return new IconButton(
      icon: const Icon(Icons.help),
      onPressed: () {
        showDialog<Null>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return new AlertDialog(
              title: new Text(helpTitle),
              content: new Text(helpText.replaceAll("\n", " "), softWrap: true)
            );
          }
        );
      },
    );
  }

  List<Widget> _snowLocation() {
    ValueChanged onChanged = (newValue) => setState(() => _locationOfProblem = newValue);

    return [
      new Row(
        children: <Widget>[
          new Radio(
            value: ProblemLocation.Sidewalk,
            groupValue: _locationOfProblem,
            onChanged: onChanged
          ),
          new Text('Sidewalk'),
          new Radio(
            value: ProblemLocation.CurbCut,
            groupValue: _locationOfProblem,
            onChanged: onChanged
          ),
          new Text('Curb Cut/Crosswalk')
        ],
      ),
      new Row(
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: new Text(
              'Location of clearence problem.',
              style: Theme.of(context).textTheme.caption.copyWith(
                fontSize: 10.0,
                color: Colors.black87
              ),
              textAlign: TextAlign.left,
            )
          ),
        ]
      ),
      new Divider(height: 8.0)
    ];
  }

  List<Widget> _snowCoverage() {
    ValueChanged onChanged = (newValue) => setState(() => _typeOfProblem = newValue);

    return [
      new Row(
        children: <Widget>[
          new Radio(
            value: Coverage.Snow,
            groupValue: _typeOfProblem,
            onChanged: onChanged
          ),
          new Text('Snow'),
          new Radio(
            value: Coverage.Slippery,
            groupValue: _typeOfProblem,
            onChanged: onChanged
          ),
          new Text('Ice'),
          new Radio(
            value: Coverage.SnowBank,
            groupValue: _typeOfProblem,
            onChanged: onChanged
          ),
          new Text('Snow Bank'),
        ],
      ),
      new Row(
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: new Text(
              'Type of clearence problem.',
              style: Theme.of(context).textTheme.caption.copyWith(
                fontSize: 10.0,
                color: Colors.black87
              ),
              textAlign: TextAlign.left,
            )
          ),
        ]
      ),
      new Divider(height: 8.0)
    ];
  }

  static const _bylawHelpTitle = 'Snow clearing bylaw';
  static const _bylawHelpText = '''
The sidewalk clearing bylaw is only in effect when there has been no snowfall for
at least 24 hours.  This field indicates our best guess about whether the bylaw is
in effect, based on the day of the week, and the time of the last snowfall.  It is
still valuable to report uncleared sidewalks to bylaw when the bylaw is not in effect
as the bylaw officers will inspect the property when the bylaw does come into effect.
Due to data limitations, this field only considers previous days, if it has snowed at
all on this day, the bylaw has been reset.
  ''';

  static const _complaintTitle = 'Submitting complaints to bylaw';
  static const _complaintText = '''
We have attemped to enable the app to submit complaints to the city's bylaw
enforcement.  This means different things in each of the three cities, and
since this is not a city endorsed app, there is no guarantee that bylaw will
actually respond to these complaints.  This checkbox will be disabled if the
location selected is outside of one of the cities where bylaw enforcement
is supported.
  ''';

  Widget _bylawComplaint() {
    return new Row(
      children: <Widget>[
        new Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: new Checkbox(
            value: _submitBylawComplaint,
            onChanged: (checked) => setState(() => _submitBylawComplaint = checked),
          )
        ),
        new Expanded(child: new Text('Submit complaint to bylaw')),
        _helpIcon(_complaintTitle, _complaintText)
      ],
    );
  }

  static const _sidewalksTitle = '# of sidewalks affected';
  static const _sidewalksText = '''
This field allows you to indicate to us that there are several properties with
blocked sidewalks in the area.  We use this information to help understand how
many properties are affected without requiring you to submit multiple complaints.
You're welcome to submit multiple complaints if you like.  Sidewalks should be
adjacent, or nearly adjacent to the complaint address you submit, if they are
further you should submit another report for the other address.  Most bylaw
officers will also inspect adjacent sidewalks as well when inspecting addresses.
  ''';

  Widget _sidewalksAffected() {
    return new Stack(
      children: [
        new Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: new Row(
            children: <Widget>[
              new Expanded(
                child: new Slider(
                  value: _numberOfAffectedSidewalks,
                  min: 1.0,
                  max: 6.0,
                  divisions: 5,
                  onChanged: (value) => setState(() => _numberOfAffectedSidewalks = value),
                  label: '${_numberOfAffectedSidewalks.toStringAsFixed(0)} sidewalks affected'
                )
              ),
              _helpIcon(_sidewalksTitle, _sidewalksText)
            ]
          )
        ),
        new Positioned(
          bottom: 0.0,
          left: 0.0,
          child: new Row(
            children: <Widget>[
              new Padding(
                padding: const EdgeInsets.only(left: 18.0, bottom: 2.0),
                child: new Text(
                  '# of affected sidewalks.',
                  style: Theme.of(context).textTheme.caption.copyWith(
                    fontSize: 10.0,
                    color: Colors.black87
                  ),
                  textAlign: TextAlign.left,
                )
              ),
            ]
          )
        )
      ]
    );
  }

  void _submitReport() {}
}
