import 'package:flutter/material.dart';

import 'package:clearwalks/initial_screen.dart';
import 'package:clearwalks/home.dart';
import 'package:clearwalks/previous_reports.dart';

void main() {
  runApp(new MaterialApp(
    title: 'ClearWalks',
    theme: new ThemeData(primarySwatch: Colors.green),
    routes: <String, WidgetBuilder>{
      '/': (BuildContext context) => new InitialScreen(),
      '/home': (BuildContext context) => new Home(),
      '/previous': (BuildContext context) => new PreviousReports()
    },
    initialRoute: '/',
  ));
}