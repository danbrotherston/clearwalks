import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:clearwalks/consts.dart';

class AddressField extends StatefulWidget {
  final Map<String, double> currentLocation;
  final AddressFieldState state;

  AddressField({@required this.currentLocation, @required this.state});

  @override
  State<StatefulWidget> createState() => state;
}

class AddressFieldState extends State<AddressField> {
  String _hintText = '123 First St. Kitchener, ON';
  Client _http = new Client();

  List<Address> addresses = [];
  String get currentAddress => addresses.length > 0 ? addresses.first.printable : "";

  @override
  void initState() {
    super.initState();
    this._reverseGeocodeCurrentLocation();
  }

  @override
  void dispose() {
    _http.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(AddressField oldWidget) {
    super.didUpdateWidget(oldWidget);
    this._reverseGeocodeCurrentLocation();
  }

  void _reverseGeocodeCurrentLocation() async {
    AddressField currentWidget = this.widget;

    if (currentWidget.currentLocation == null ||
        currentWidget.currentLocation['latitude'] == null ||
        currentWidget.currentLocation['longitude'] == null) {
      return;
    }

    double lat  = currentWidget.currentLocation['latitude'];
    double long = currentWidget.currentLocation['longitude'];

    Response result = await _http.get("https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$long&key=$API_KEY");

    if (currentWidget != widget || !mounted) return;

    addresses = await _fromReverseGeocodeResponse(result);

    if (currentWidget != widget || !mounted) return;

    if (addresses.length > 0) setState(() => _hintText = addresses.first.printable);
  }

  @override
  Widget build(BuildContext context) {
    return new TextField(decoration: InputDecoration(
      hintText: _hintText
    ));
  }
}

List<Address> _parseBody(String body) {
  final parsedBody = json.decode(body);
  
  if (parsedBody['status'] != 'OK') return [];

  if (parsedBody['results'] == null || parsedBody['results'] is! List) return [];

  return Address.fromJsonList(parsedBody['results']);
}

Future<List<Address>> _fromReverseGeocodeResponse(Response response) async {
  if (response.statusCode != 200) return new Future.value(null);

  return compute(_parseBody, response.body);
}

class Address {
  final String street;
  final String number;
  final String city;

  Address({@required this.street, @required this.number, @required this.city});

  String get printable => "$number $street, $city";

  String toString() => printable;

  static List<Address> fromJsonList(List<dynamic> jsonAddresses) {
    return jsonAddresses.map<Address>(fromJson).where((address) => address != null).toList();
  }

  static Address fromJson(dynamic json) {
    String street = '';
    String number = '';
    String city = '';

    if (json is! Map<String, dynamic>) return null;

    dynamic components = json['address_components'];

    if (components == null || components is! List<dynamic>) return null;

    for (dynamic component in components) {
      if (component is! Map<String, dynamic>
       || component['types'] == null
       || component['types'] is! Iterable) return null;

      List<dynamic> types = List.of(component['types']);

      if (types.contains('street_number')) number = component['long_name'] ?? '';
      if (types.contains('route'))         street = component['short_name'] ?? '';
      if (types.contains('locality'))      city = component['long_name'] ?? '';
    }

    return Address(
      street: street,
      number: number,
      city: city
    );
  }
}