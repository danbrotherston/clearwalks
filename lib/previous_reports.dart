import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:intl/intl.dart';

import 'package:clearwalks/consts.dart';
import 'package:clearwalks/home.dart';

class PreviousReports extends StatefulWidget {
  @override State<StatefulWidget> createState() => new _PreviousReportsState();
}

class _PreviousReportsState extends State<PreviousReports> {
  final DateFormat _format = new DateFormat('EEEE LLLL d h:m ');

  FirebaseUser _user;
  int _openIndex = -1;

  @override void initState() {
    super.initState();
    FirebaseAuth.instance.currentUser().then((FirebaseUser user) => setState(() => _user = user));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Clear Walks')),
      body: new Column(
        children: <Widget>[
          new ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            title: new Text('If you have previous submitted a report, but encounter the same uncleared sidewalk on a second trip, please report again.')),
          _user == null
            ? new Center(child: new CircularProgressIndicator())
            : new FirebaseAnimatedList(
                shrinkWrap: true,
                query: FirebaseDatabase
                        .instance
                        .reference()
                        .child(FB_REPORTS_PATH)
                        .orderByChild(FB_REPORT_USER_PATH)
                        .equalTo(_user.uid),

                itemBuilder: (BuildContext context, DataSnapshot snapshot, Animation<double> animation, int index) {
                  if (index == _openIndex) {
                    var boolToString = (bool b) => b ? 'Yes' : 'No';
                    var problemLocationToString = (int i) => ProblemLocation.values[i].toString();
                    var problemTypeToString = (int i) => Coverage.values[i].toString();

                    return new ListTile(
                      onTap: () => setState(() => _openIndex = -1),
                      title: new Text(snapshot.value[FB_REPORT_ADDRESS_PATH]),
                      subtitle: new Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          new Text('Date: ' + _format.format(DateTime.parse(snapshot.value[FB_REPORT_DATE_PATH]))),
                          new Text('Location: [${snapshot.value[FB_REPORT_SELECTED_LAT_PATH]}, ${snapshot.value[FB_REPORT_SELECTED_LONG_PATH]}]'),
                          new Text('Manually Repositioned: ${boolToString(snapshot.value[FB_REPORT_REPOSITIONED_PATH])}'),
                          new Text('Reported To Bylaw: ${boolToString(snapshot.value[FB_REPORT_BYLAW_REPORTED_PATH])}'),
                          new Text('Number Sidewalks Affected: ${snapshot.value[FB_REPORT_NUM_WALKS_PATH]}'),
                          new Text('Problem Location: ${problemLocationToString(snapshot.value[FB_REPORT_PROBLEM_LOC_PATH])}'),
                          new Text('Problem Type: ${problemTypeToString(snapshot.value[FB_REPORT_PROBLEM_TYPE_PATH])}'),
                        ]
                      )  
                    );
                  } else {
                    return new ListTile(
                      onTap: () => setState(() => _openIndex = index),
                      title: new Text(snapshot.value[FB_REPORT_ADDRESS_PATH]),
                      subtitle: new Text(_format.format(DateTime.parse(snapshot.value[FB_REPORT_DATE_PATH]))),
                    );
                  }
                }
              )
            ],
          )
      );
  }
}