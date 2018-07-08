import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class LocationMap extends StatefulWidget {
  final Map<String, double> _currentLocation;
  final ValueChanged<Offset> onPanEnd;
  final Function onPanStart;

  static const Map<String, double> _defaultLocation = {
    'latitude': 43.458186,
    'longitude': -80.5186281,
    'accuracy': 5000.0
  };

  LocationMap({
    currentLocation,
    @required this.onPanEnd,
    @required this.onPanStart})
  : this._currentLocation = currentLocation ?? _defaultLocation;

  @override
  State<StatefulWidget> createState() => new LocationMapState();
}

class LocationMapState extends State<LocationMap> {
  ui.Image _mapImage;
  Offset _panOffset = Offset.zero;

  static const apiKey = 'AIzaSyAInd7jJu_aAaNnPBHpNpZaQyr0sa-upuo';

  @override
  void initState() {
    super.initState();
    _readImage();
  }

  void _readImage() async {
    String imageUrl = "https://maps.googleapis.com/maps/api/staticmap?center=${widget._currentLocation["latitude"]},${widget._currentLocation["longitude"]}&zoom=18&size=640x400&key=$apiKey";
    Uint8List bytes = await http.readBytes(imageUrl);
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo frame = await codec.getNextFrame();
    setState(() {
      _mapImage = frame.image;
      _panOffset = Offset.zero;
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
    const double pinHeight = 48.0;

    return _mapImage == null
      ? new Container()
      : new GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          this.setState(() => _panOffset = _panOffset.translate(details.delta.dx, details.delta.dy));
        },
        behavior: HitTestBehavior.opaque,
        child: new Stack(
          children: <Widget>[
            new ClipRect(
              child: new CustomPaint(
                size: Size.infinite,
                painter: new _OffsetCenterImagePainter(
                  image: _mapImage,
                  offset: _panOffset,
                  scale: 1.0
                )
              )
            ),
            new Center(
              child: new Padding(  // Padding ensures the tip of the pointer is at the centre of te map
                padding: const EdgeInsets.only(bottom: pinHeight),
                child: Image.asset('assets/map_pin.png', height: pinHeight)
              )
            ),
            new Positioned(
              child: new GPSGauge(strength: _interpretAccuracy()),
              top: 8.0,
              right: 8.0,
            )
          ]
        )
      );
  }

  GPSStrength _interpretAccuracy() {
    if (_panOffset != Offset.zero)
      return GPSStrength.ManuallyRepositioning;

    if (widget._currentLocation['accuracy'] == null || widget._currentLocation['accuracy'] < 0)
      return GPSStrength.NoSignal;

    if (widget._currentLocation['accuracy'] < 13)
      return GPSStrength.StrongSignal;

    if (widget._currentLocation['accuracy'] < 20)
      return GPSStrength.MediumSignal;

    if (widget._currentLocation['accuracy'] < 100)
      return GPSStrength.WeakSignal;

    else return GPSStrength.NoSignal;
  }
}

enum GPSStrength {
  ManuallyRepositioning,
  NoTracking,
  NoSignal,
  WeakSignal,
  MediumSignal,
  StrongSignal
}

class GPSGauge extends StatelessWidget {
  final GPSStrength strength;

  GPSGauge({this.strength});

  static const String _manual = 'Manually respositioning map.';
  static const String _noTracking = 'GPS is not tracking.';
  static const String _tracking = 'GPS signal strength.';

  static const Color _noSignal = Colors.grey;
  static const Color _weakSignal = Colors.red;
  static const Color _mediumSignal = Colors.orange;
  static const Color _strongSignal = Colors.green;

  @override
  Widget build(BuildContext context) {
    Color color1 = _noSignal, color2 = _noSignal, color3 = _noSignal;
    switch (strength) {
      case GPSStrength.ManuallyRepositioning:
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
              strength == GPSStrength.NoTracking
                ? _noTracking 
                : strength == GPSStrength.ManuallyRepositioning ? _manual : _tracking,
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

class _OffsetCenterImagePainter extends CustomPainter {
  const _OffsetCenterImagePainter({this.image, this.offset, this.scale});

  final ui.Image image;
  final Offset offset;
  final double scale;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    Size imageSize = new Size(image.width.toDouble(), image.height.toDouble());
    Size targetSize = imageSize * scale;

    paintImage(
      canvas: canvas,
      rect: offset.translate(-canvasSize.width / 2, -canvasSize.height / 2) & targetSize,
      image: image,
      fit: BoxFit.fill,
    );
  }

  @override
  bool shouldRepaint(_OffsetCenterImagePainter old) {
    return old.image != image || old.offset != offset || old.scale != scale;
  }
}