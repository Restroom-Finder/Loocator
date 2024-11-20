import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loocator/models/restroom.dart';
import 'package:loocator/utils/firestore.dart';
import 'package:loocator/widgets/star_rating.dart';

// ignore: must_be_immutable
class ReviewPage extends StatefulWidget {
  final Restroom restroom;

  ReviewPage({
    super.key,
    required this.restroom,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool updatedRating = false;
  double newRating = 0.0;
  TextEditingController description = TextEditingController();

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add a Review',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      body: SizedBox(
        height: 500,
        width: double.infinity,
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 75,
                      ),
                      // Display the rating as a fraction
                      Text(
                        '$newRating/5.0',
                        style: const TextStyle(fontSize: 16),
                      ),
                      // Rate the restroom out of 5 stars
                      StarRating(
                          rating: newRating,
                          onRatingChanged: (rating) => setState(() {
                                newRating = rating;
                                updatedRating = true;
                              })),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text('Rate this Restroom'),
                      const SizedBox(
                        height: 20,
                      ),
                      // Descriptive Rating
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22.0),
                        child: SizedBox(
                          width: double.maxFinite,
                          child: TextField(
                            maxLines: null,
                            controller: description,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              labelText: 'Write a Description (Optional)',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      // Submit Button
                      ElevatedButton(
                          onPressed: (updatedRating)
                              ? () {
                                  setState(() {
                                    addReview(
                                        widget.restroom,
                                        currentUser!,
                                        (description.text.isNotEmpty)
                                            ? description.text
                                            : null,
                                        newRating);
                                    Navigator.pop(context);
                                    showMessage('Thank you for Reviewing!');
                                  });
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColorLight),
                          child: const Text('Submit Review')),
                    ]),
              ),
            )
          ],
        ),
      ),
    );
  }

  void showMessage(String message) {
    final SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
