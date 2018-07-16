import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';

import 'package:csv/csv.dart';
import 'package:http/http.dart';

enum SnowBylaw {
  Unknown,
  InEffect,
  NotInEffect
}

class SnowBylawWidget extends StatefulWidget {
  final Widget helpIcon;

  SnowBylawWidget({this.helpIcon});

  @override
  State<SnowBylawWidget> createState() => new SnowBylawWidgetState();
}

class SnowBylawWidgetState extends State<SnowBylawWidget> {
  SnowBylaw _isBylawInEffect = SnowBylaw.Unknown;

  @override
  void initState() {
    super.initState();
    _checkBylaw();
  }

  T _safeElementAt<T>(List<T> list, int index) {
    try { return list.elementAt(index); }
    catch(error) { return null; }
  }

  void _checkBylaw() async {
    DateTime currentDate = DateTime.now();

    // Bylaw doesn't operate on weekends.
    List<int> weekendDays = [DateTime.saturday, DateTime.sunday];
    if (weekendDays.contains(currentDate.weekday)) {
      setState(() => _isBylawInEffect = SnowBylaw.NotInEffect);
      return;
    }

    DatabaseReference bylawDateRef = FirebaseDatabase.instance.reference().child('bylaw/date_checked');
    DatabaseReference bylawInForceRef = FirebaseDatabase.instance.reference().child('bylaw/in_force');

    DateTime date = DateTime.tryParse((await bylawDateRef.once()).value ?? "");

    if (_isSameDay(date, DateTime.now())) {
      SnowBylaw bylaw = _safeElementAt(SnowBylaw.values, (await bylawInForceRef.once()).value ?? SnowBylaw.Unknown.index)
        ?? SnowBylaw.Unknown;

      if (bylaw != SnowBylaw.Unknown) {
        setState(() => _isBylawInEffect = bylaw);
        return;
      }
    }

    Response result = await get('http://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv&stationID=48569&Year=${currentDate.year}&Month=${currentDate.month}&Day=${currentDate.day}&timeframe=2');

    SnowBylaw bylaw = result.statusCode == 200
      ? await compute(_computeBylaw, result.body)
      : SnowBylaw.Unknown;

    setState(() => _isBylawInEffect = bylaw);

    await bylawInForceRef.set(bylaw.index);
    bylawDateRef.set(DateTime.now().toIso8601String());
  }

  Widget build(BuildContext context) {
    TextSpan bylawInEffectText;
    switch(_isBylawInEffect) {
      case SnowBylaw.InEffect:
        bylawInEffectText = new TextSpan(text: 'in effect', style: new TextStyle(color: Colors.green));
        break;

      case SnowBylaw.NotInEffect:
        bylawInEffectText = new TextSpan(text: 'not in effect', style: new TextStyle(color: Colors.red));
        break;

      case SnowBylaw.Unknown:
      default:
        bylawInEffectText = new TextSpan(text: '...', style: new TextStyle(color: Colors.grey));
    }

    return new Padding(
      padding: const EdgeInsets.only(left: 18.0),
      child: new Row(
        children: <Widget>[
          new Expanded(
            child: new RichText(
              text: new TextSpan(
                text: 'Snow clearing bylaw is ',
                style: Theme.of(context).textTheme.body1,
                children: <TextSpan>[
                  bylawInEffectText,
                  new TextSpan(text: '.')
                ],
              ),
            )
          ),
          widget.helpIcon
        ]
      )
    );
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return
        date1 != null
      && date2 != null
      && date1.day == date2.day
      && date1.month == date2.month
      && date1.year == date2.year;
  }

  static SnowBylaw _computeBylaw(String responseBody) {
    List<List<dynamic>> weatherData = const CsvToListConverter(eol: '\n').convert(responseBody);
    weatherData.removeWhere((row) => row.length <= 2); // remove intro headers from the csv data.
    int indexOfDateTime =      weatherData.first.indexOf("Date/Time");
    int indexOfTotalSnow =     weatherData.first.indexOf("Total Snow (cm)");
    int indexOfTotalSnowFlag = weatherData.first.indexOf("Total Snow Flag");
    int indexOfTotalPrecip =   weatherData.first.indexOf("Total Precip (mm)");

    if (indexOfDateTime != 0 || indexOfTotalSnow == -1 || indexOfTotalPrecip == -1 || indexOfTotalSnowFlag == -1)
      return SnowBylaw.Unknown;

    // Find the last weekday.
    DateTime previousDay = DateTime.now().subtract(const Duration(days: 1));
    /*DateTime lastWeekday = DateTime.now().subtract(const Duration(days: 1));
    if (lastWeekday.weekday == DateTime.sunday) lastWeekday = lastWeekday.subtract(new Duration(days: 1));
    if (lastWeekday.weekday == DateTime.saturday) lastWeekday = lastWeekday.subtract(new Duration(days: 1));*/

    for (List<dynamic> row in weatherData) {
      DateTime rowDate = DateTime.tryParse(row.elementAt(indexOfDateTime).toString());
      if (rowDate == null) continue;

      if (_isSameDay(rowDate, previousDay)) {
        double snow = 0.0;
        if (row.elementAt(indexOfTotalSnowFlag).toString() != 'M' && row.elementAt(indexOfTotalSnow).toString().isNotEmpty) {
          snow = double.tryParse(row.elementAt(indexOfTotalSnow).toString());
        } else {
          snow = double.tryParse(row.elementAt(indexOfTotalPrecip).toString());
        }

        if (snow == null) return SnowBylaw.Unknown;
        if (snow <= 0) return SnowBylaw.InEffect;
        else return SnowBylaw.NotInEffect;
      }
    }

    return SnowBylaw.Unknown;
  }
}
