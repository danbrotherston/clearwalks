import 'dart:core';

import 'package:flutter/material.dart';

import 'package:clearwalks/location_map.dart';
import 'package:clearwalks/address_field.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  bool _submitBylawComplaint = true;
  double _numberOfAffectedSidewalks = 1.0;

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
      floatingActionButton: new FloatingActionButton(
        tooltip: 'Submit this sidewalk report.',
        child: new Icon(Icons.add),
        onPressed: _submitReport,
      ),
      body: new Column(
        children: <Widget>[
          _bylawInEffect(),
          _bylawComplaint(),
          new Divider()
        ]
        ..addAll(_snowCoverage())
        ..addAll(_snowLocation())
        ..add(_sidewalksAffected())
        ..add(new LocationMap())
        ..add(new Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: new AddressField()
        ))
      )
    );
  }

  Widget _helpIcon(String helpTitle, String helpText) {
    return new IconButton(
      icon: const Icon(Icons.help),
      onPressed: () {},
    );
  }

  List<Widget> _snowLocation() {
    return [
      new Divider()
    ];
  }

  List<Widget> _snowCoverage() {
    return [
      new Divider()
    ];
  }

  static const _bylawHelpTitle = 'Snow clearing bylaw';
  static const _bylawHelpText = '''
    The sidewalk clearing bylaw is only in effect when there has been no snowfall for
    at least 24 hours.  This field indicates our best guess about whether the bylaw is
    in effect, based on the day of the week, and the time of the last snowfall.  It is
    still valuable to report uncleared sidewalks to bylaw when the bylaw is not in effect
    as the bylaw officers will inspect the property when the bylaw does come into effect.
  ''';

  Widget _bylawInEffect() {
    return new Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: new Row(
        children: <Widget>[
          new RichText(
            text: new TextSpan(
              text: 'The snow clearing bylaw is ',
              style: Theme.of(context).textTheme.body1,
              children: <TextSpan>[
                new TextSpan(text: 'not in effect', style: new TextStyle(color: Colors.red)),
                new TextSpan(text: '.')
              ],
            ),
          ),
          _helpIcon(_bylawHelpTitle, _bylawHelpText)
        ]
      )
    );
  }

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
        new Checkbox(
          value: _submitBylawComplaint,
          onChanged: (checked) => setState(() => _submitBylawComplaint = checked),
        ),
        new Text('Submit complaint to bylaw'),
        _helpIcon(_complaintTitle, _complaintText)
      ],
    );
  }

  String numberValidator(String value) {
    if (value == null) {
      return null;
    }

    final result = num.parse(value, (string) => null);
    if (result == null) {
      return '"$value" is not a valid number';
    }

    return null;
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
    return new Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: new Row(
        children: <Widget>[
          new Expanded(
            child: new Slider(
              value: _numberOfAffectedSidewalks,
              min: 1.0,
              max: 6.0,
              divisions: 5,
              onChanged: (value) => setState(() => _numberOfAffectedSidewalks = value),
              label: '# of sidewalks affected'
            )
          ),
          _helpIcon(_sidewalksTitle, _sidewalksText)
        ]
      )
    );
  }

  void _submitReport() {}
}