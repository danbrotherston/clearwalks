import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new HomeState();
}

class HomeState extends State<Home> {
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
      body: new Center(child: new Text("Home Page"))
    );
  }

  void _submitReport() {}
}