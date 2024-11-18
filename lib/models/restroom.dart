import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class Restroom {
  final LatLng position;
  final String placeName;
  final String address;
  List<String>? reviews;
  List<double>? ratings;
  bool isAccessible;

  Restroom({
    required this.position,
    required this.placeName,
    required this.address,
    this.reviews,
    this.ratings,
    this.isAccessible = false,
  });

  @override
  String toString() {
    return '$placeName, $address, $position';
  }
}
