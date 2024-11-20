import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:loocator/models/restroom.dart';
import 'package:loocator/models/review.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<List<Restroom>> buildRestrooms() async {
  final rawData = await _firestore.collection('restrooms').get();
  final dataList = rawData.docs;
  List<Restroom> restrooms = [];

  for (QueryDocumentSnapshot doc in dataList) {
    restrooms.add(Restroom(
        position: LatLng(
            latitude: doc.get('latitude'), longitude: doc.get('longitude')),
        placeName: doc.get('place name'),
        address: doc.get('address'),
        reviews: ((await _convertToList(doc, 'review')) == null)
            ? null
            : (await _convertToList(doc, 'review'))!.cast(),
        ratings: ((await _convertToList(doc, 'rating')) == null)
            ? null
            : (await _convertToList(doc, 'rating'))!.cast()));
  }

  return restrooms;
}

Future<Restroom> updateRestroom(Restroom restroom) async {
  final rawData = await _firestore
      .collection('restrooms')
      .where('place name', isEqualTo: restroom.placeName)
      .get();
  final reference = rawData.docs[0];
  final data = reference.data();

  restroom = Restroom(
    position: LatLng(latitude: data['latitude'], longitude: data['longitude']),
    placeName: data['place name'],
    address: data['address'],
    reviews: (await _convertToList(reference, 'review'))!.cast(),
    ratings: (await _convertToList(reference, 'rating'))!.cast(),
  );

  return restroom;
}

Future<List<dynamic>?> _convertToList(
    QueryDocumentSnapshot<Object?> doc, String path) async {
  final rawData = await doc.reference.collection('reviews').get();
  final docs = rawData.docs;
  List<dynamic>? data = [];

  try {
    for (QueryDocumentSnapshot doc in docs) {
      if (doc.get(path) != null) {
        if (path == 'rating') {
          data.add(doc.get(path));
        } else if (path == 'review') {
          data.add(Review(
              displayName: doc.get('display name'),
              review: doc.get('review'),
              rating: doc.get('rating'),
              timestamp: doc.get('timestamp')));
        }
      }
    }

    return data.isEmpty ? null : data;
  } on StateError {
    return null;
  }
}

void addReview(
    Restroom restroom, User currentUser, String? review, double rating) async {
  await _firestore
      .collection('restrooms')
      .doc(restroom.placeName)
      .collection('reviews')
      .doc(currentUser.uid)
      .set({
    'display name': currentUser.displayName,
    'review': review,
    'rating': rating,
    'timestamp': Timestamp.now(),
  });
}
