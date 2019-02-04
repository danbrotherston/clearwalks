import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'dart:io';

class UploadImage extends StatefulWidget {
  final Map<String, double> location;

  UploadImage(this.location);

  @override
  _UploadImageState createState() => new _UploadImageState();
}

class _UploadImageState extends State<UploadImage> {
  File _image;

  final TextEditingController _commentTextController;
  _UploadImageState() : _commentTextController = new TextEditingController();

  static const _uploadDescription = '''
Have a particularly bad uncleared sidewalk to show or just want to document what your bad
experience? Send us a photo for our sidewalks of shame map, and maybe we'll feature your
photo at City council.

~~(All photos will be public after uploading, only upload photos you're permitted too).
  ''';
  
  void _submitPhoto() {}
  void _takePhoto() {}
  void _selectPhoto() {}

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Clear Walks')),
      body: new Column(
        children: <Widget>[
          MediaQuery.of(context).viewInsets.bottom == 0
            ? new Padding(
              padding: const EdgeInsets.all(32),
              child: new Text(_uploadDescription.replaceAll('\n', ' ').replaceAll('~', '\n'))
            )
            : new Container(),
          new Expanded(
            child: new Center(
              child: new Padding(
                padding: const EdgeInsets.symmetric(horizontal:32),
                child: new Container(
                  decoration: new BoxDecoration(
                    color: Colors.grey,
                    borderRadius: new BorderRadius.circular(32)
                  ),
                  child: new Center(
                    child: new Row(
                      children: <Widget>[
                        new Expanded(
                          child: new FlatButton.icon(
                            icon: new Icon(Icons.camera),
                            label: new Text("Take a Photo"),
                            onPressed: _takePhoto,
                          )
                        ),
                        new Container(
                          width: 1,
                          color: Colors.black
                        ),
                        new Expanded(
                          child: new FlatButton.icon(
                            icon: new Icon(Icons.image),
                            label: new Text("Select a Photo"),
                            onPressed: _selectPhoto,
                          )
                        )
                      ]
                    )
                  )
                )
              )
            )
          ),
          new Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: new TextField(
              decoration: new InputDecoration(hintText: "Leave a comment about your picture, or your experience."),
              controller: _commentTextController,
              maxLines: 5,
            )
          ),
          new Padding(
            padding: new EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom == 0 ? 32 : 0),
            child: new RaisedButton(
              child: new Text("Submit Photo"),
              onPressed: _image != null ? _submitPhoto : null
            )
          )
        ]
      )
    );
  }
}