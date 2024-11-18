import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:loocator/models/restroom.dart';

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
        reviews: ((await _convertToList(doc, 'reviews')) == null)
            ? null
            : (await _convertToList(doc, 'reviews'))!.cast()));
  }

  return restrooms;
}

Future<void> updateRestrooms(Restroom restroom) async {
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
    reviews: await _convertToList(reference, 'review') as List<String>?,
    ratings: (await _convertToList(reference, 'rating'))!.cast<double>(),
  );
}

Future<List<dynamic>?> _convertToList(
    QueryDocumentSnapshot<Object?> doc, String path) async {
  final rawData = await doc.reference.collection('reviews').get();
  final docs = rawData.docs;
  List<dynamic>? data = [];

  try {
    for (QueryDocumentSnapshot doc in docs) {
      if (doc.get(path) != null) data.add(doc.get(path));
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
