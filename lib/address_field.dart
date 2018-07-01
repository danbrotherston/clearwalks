import 'package:flutter/material.dart';

class AddressField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new TextField(decoration: InputDecoration(
      hintText: '123 First St. Kitchener, ON'
    ));
  }
}