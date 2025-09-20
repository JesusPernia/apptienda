import 'package:flutter/material.dart';

class Nav {
  Nav.go(context, String route) {
    Navigator.popAndPushNamed(context, route);
  }

  Nav.push(context, String route) {
    Navigator.pushNamed(context, route);
  }

  Nav.replace(context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }
}
