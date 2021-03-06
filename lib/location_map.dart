import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

import 'package:clearwalks/consts.dart';

class LocationMap extends StatefulWidget {
  final Map<String, double> _currentLocation;
  final ValueChanged<Offset> onPanEnd;
  final Function onPanStart;
  final Function onTapGPSMode;

  static const Map<String, double> _defaultLocation = {
    'latitude': 43.458186,
    'longitude': -80.5186281,
    'accuracy': 5000.0
  };

  LocationMap({
    currentLocation,
    @required this.onPanEnd,
    @required this.onPanStart,
    @required this.onTapGPSMode})
  : this._currentLocation = currentLocation ?? _defaultLocation;

  @override
  State<StatefulWidget> createState() => new LocationMapState();
}

class LocationMapState extends State<LocationMap> {
  ui.Image _mapImage;

  // The offset of the map from its centre location, accumulates after repeated
  // pans before image reloads.
  Offset _imageOffset = Offset.zero;

  // The distance the map has been panned by the user.
  Offset _panOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _panOffset = Offset.zero;
    _imageOffset = Offset.zero;
    _readImage(_imageOffset);
  }

  void _readImage(Offset offset) async {
    String imageUrl = "https://maps.googleapis.com/maps/api/staticmap?scale=2&center=${widget._currentLocation["latitude"]},${widget._currentLocation["longitude"]}&zoom=17&size=640x640&key=$API_KEY";
    Uint8List bytes = await http.readBytes(imageUrl);
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo frame = await codec.getNextFrame();
    if (offset == _imageOffset) {
      // If this isn't for the current image offset, don't display it, a new image will be coming.
      setState(() {
        _mapImage = frame.image;
        _imageOffset = Offset.zero;
      });
    }
  }

  @override
  void didUpdateWidget(LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._currentLocation['longitude'] != widget._currentLocation['longitude'] ||
        oldWidget._currentLocation['latitude'] != widget._currentLocation['latitude']) {
      _readImage(_imageOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double pinHeight = 48.0;

    return _mapImage == null
      ? new Container()
      : new GestureDetector(
        onPanStart: (DragStartDetails details) => this.widget.onPanStart(),
        onPanEnd: (DragEndDetails details) {
          this.widget.onPanEnd(_panOffset);
          _imageOffset += _panOffset;
          _panOffset = Offset.zero;
        },
        onPanUpdate: (DragUpdateDetails details) =>
          this.setState(() => _panOffset = _panOffset.translate(details.delta.dx, details.delta.dy)),
        behavior: HitTestBehavior.opaque,
        child: new Stack(
          children: <Widget>[
            new ClipRect(
              child: new CustomPaint(
                size: Size.infinite,
                painter: new _OffsetCenterImagePainter(
                  image: _mapImage,
                  offset: _panOffset + _imageOffset,
                  scale: 0.5
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
              child: new GPSGauge(strength: _interpretAccuracy(), onTapGPSMode: widget.onTapGPSMode),
              top: 8.0,
              right: 8.0,
            )
          ]
        )
      );
  }

  GPSStrength _interpretAccuracy() {
    if (_panOffset != Offset.zero || widget._currentLocation['accuracy'] == null)
      return GPSStrength.ManuallyRepositioning;

    if (widget._currentLocation['accuracy'] < 0)
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
  final Function onTapGPSMode;

  GPSGauge({@required this.strength, @required this.onTapGPSMode});

  static const String _manual = 'Manually respositioning map.';
  static const String _noTracking = 'GPS is not tracking.';
  static const String _tracking = 'GPS signal strength.';

  static const Color _noSignal = Colors.grey;
  static const Color _weakSignal = Colors.red;
  static const Color _mediumSignal = Colors.orange;
  static const Color _strongSignal = Colors.green;

  @override
  Widget build(BuildContext context) {
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
            children: strength != GPSStrength.ManuallyRepositioning
              ? _buildSignalGauge()
              : [
                  new IconButton(
                    icon: new ImageIcon(new AssetImage('assets/satellite.png')),
                    onPressed: this.onTapGPSMode
                  )
                ]
          )
        ]
      )
    );
  }

  static const double spacing = 4.0;

  List<Widget> _buildSignalGauge() {
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

    const double boxHeight = 12.0;
    const double boxWidth = 6.0;

    return [
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
    ];
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
    Offset targetOffset = offset
      .translate(
        (targetSize.width - canvasSize.width) * -0.5,
        (targetSize.height - canvasSize.height) * -0.5
      );


    paintImage(
      canvas: canvas,
      rect: targetOffset & targetSize,
      image: image,
      fit: BoxFit.cover,
    );
  }

  @override
  bool shouldRepaint(_OffsetCenterImagePainter old) {
    return old.image != image || old.offset != offset || old.scale != scale;
  }
}