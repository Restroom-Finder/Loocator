import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String displayName;
  final String review;
  final double rating;
  final Timestamp timestamp;

  Review(
      {required this.displayName,
      required this.review,
      required this.rating,
      required this.timestamp});
}
