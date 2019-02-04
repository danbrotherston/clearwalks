import 'package:flutter/material.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

import 'package:clearwalks/consts.dart';

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
  
  void _submitPhoto() {
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString() + Uuid().v4().toString();
    final StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    final StorageUploadTask uploadTask = reference.putFile(_image);

    uploadTask.onComplete.then((StorageTaskSnapshot snapshot) async {
      if (snapshot.error == null) {
        try {
          FirebaseUser user = await FirebaseAuth.instance.currentUser();
          String downloadUrl = await snapshot.ref.getDownloadURL();

          Map<String, dynamic> reportData = {
            FB_IMAGE_DATE_PATH: DateTime.now().toIso8601String(),
            FB_IMAGE_USER_PATH: user.uid,
            FB_IMAGE_EMAIL_PATH: user.email,
            FB_IMAGE_LAT_PATH: this.widget.location['latitude'] ?? "",
            FB_IMAGE_LONG_PATH: this.widget.location['longitude'] ?? "",
            FB_IMAGE_URL_PATH: downloadUrl,
            FB_IMAGE_DESCRIPTION_PATH: _commentTextController.text
          };

          String key = DateTime.now().millisecondsSinceEpoch.toString() + Uuid().v4().toString();
          DatabaseReference imageRef = FirebaseDatabase.instance.reference().child(FB_IMAGES_PATH).child(key);

          await imageRef.set(reportData);
          Navigator.of(context).pop(true);
        } catch(error) {
          Scaffold.of(context).showSnackBar(new SnackBar(
            duration: new Duration(seconds: 8),
            content: new Text("Error while adding your image to the map.  Please try again.")
          ));
        } finally {
          Navigator.of(context).pop(true);
        }
      }
    });

    showDialog(
      context: this.context,
      barrierDismissible: false,
      builder: (BuildContext context) => new StreamBuilder<StorageTaskEvent>(
        stream: uploadTask.events,
        initialData: null,
        builder: (BuildContext context, AsyncSnapshot<StorageTaskEvent> eventSnapshot) {
          String title = "Image Upload";
          String description = "";
          double progress;
          
          Map<StorageTaskEventType, String> titles = {
            null: "Preparing to Upload",
            StorageTaskEventType.failure: "Upload Failed!",
            StorageTaskEventType.pause: "Upload Paused",
            StorageTaskEventType.resume: "Upload Resumed",
            StorageTaskEventType.progress: "Upload In Progress...",
            StorageTaskEventType.success: "Upload Completed!",
          };

          FlatButton cancelButton = FlatButton(
            child: new Text("CANCEL"),
            onPressed: uploadTask.cancel,
          );

          FlatButton okButton = FlatButton(
            child: new Text("OKAY"),
            onPressed: Navigator.of(context).pop,
          );

          FlatButton actionButton = cancelButton;

          if (eventSnapshot.hasError || eventSnapshot.data?.type == StorageTaskEventType.failure) {
            title = "Upload failed";
            description = "There was an error while uploading your image.  Check the network and try again.";
            progress = 0.0;
            actionButton = okButton;
          } else {
            title = titles[eventSnapshot.data?.type];
            if (eventSnapshot.data?.type == StorageTaskEventType.progress) {
              progress = eventSnapshot.data.snapshot.bytesTransferred / eventSnapshot.data.snapshot.totalByteCount;
            } else if (eventSnapshot.data?.type == StorageTaskEventType.success) {
              progress = null;
              description = "Placing image on the map.";
              actionButton = null;
            }
          }

          if (uploadTask.isCanceled) {
            title = "Upload Cancelled";
            description = "The upload was cancelled. You can go correct your entry or use the back button to return to reporting sidewalks.";
          }

          return new Dialog(
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                new LinearProgressIndicator(value: progress ?? 1.0),
                new Padding(
                  padding: const EdgeInsets.all(16),
                  child: new Text(
                    title,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.title
                  )
                ),

                description == ""
                  ? new Container()
                  : new Padding(
                    padding: const EdgeInsets.all(16),
                    child: new Text(description, textAlign: TextAlign.left)
                  ),

                new Center(
                  child: new CircularProgressIndicator(value: progress)
                ),

                new Align(
                  alignment: Alignment.centerRight,
                  child: new Padding(
                    padding: const EdgeInsets.all(16),
                    child: actionButton
                  )
                )
              ],
            )
          );
        }
      )
    );
  }

  void _selectPhoto(ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);

    setState(() {
      _image = image;
    });
  }

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
                    image: _image == null
                      ? null
                      : new DecorationImage(
                        image: new FileImage(_image),
                        fit: BoxFit.cover
                      ),
                    borderRadius: new BorderRadius.circular(32)
                  ),
                  child: new Center(
                    child: new Row(
                      children: <Widget>[
                        new Expanded(
                          child: new FlatButton.icon(
                            icon: new Icon(Icons.camera),
                            label: new Text(
                              "Take a Photo",
                              style: new TextStyle(
                                shadows: <Shadow>[
                                  new Shadow(
                                    color: Colors.white,
                                    offset: new Offset(0.0, 0.0),
                                    blurRadius: 4.0
                                  )
                                ]
                              )
                            ),
                            onPressed: () => _selectPhoto(ImageSource.camera),
                          )
                        ),
                        new Container(
                          width: 1,
                          color: Colors.black
                        ),
                        new Expanded(
                          child: new FlatButton.icon(
                            icon: new Icon(Icons.image),
                            label: new Text(
                              "Select a Photo",
                              style: new TextStyle(
                                shadows: <Shadow>[
                                  new Shadow(
                                    color: Colors.white,
                                    offset: new Offset(0.0, 0.0),
                                    blurRadius: 4.0
                                  )
                                ]
                              )
                            ),
                            onPressed: () => _selectPhoto(ImageSource.gallery),
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
              textCapitalization: TextCapitalization.sentences,
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