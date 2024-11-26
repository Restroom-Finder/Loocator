import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:loocator/models/review.dart';

class Restroom {
  final LatLng position;
  final String placeName;
  final String address;
  List<Review>? reviews;
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
