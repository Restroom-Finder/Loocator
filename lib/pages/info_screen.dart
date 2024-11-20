import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loocator/models/restroom.dart';
import 'package:loocator/pages/review_page.dart';

// ignore: must_be_immutable
class InfoScreen extends StatefulWidget {
  final void Function()? onPressed;
  final int distance;
  final int time;
  Restroom restroom;

  InfoScreen({
    super.key,
    required this.onPressed,
    required this.distance,
    required this.time,
    required this.restroom,
  });

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  double? avgRating;

  @override
  Widget build(BuildContext context) {
    bool signedIn = (FirebaseAuth.instance.currentUser != null);
    bool hasReviews = (widget.restroom.reviews != null);
    bool hasRatings = (widget.restroom.ratings != null);

    _setAverage();

    return Scaffold(
        appBar: AppBar(
          title: // Place's Name
              Text(
            widget.restroom.placeName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Theme.of(context).primaryColorLight,
        ),
        body: SizedBox(
            height: 500,
            width: double.infinity,
            child: ListView(scrollDirection: Axis.vertical, children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Address
                    Text(
                      widget.restroom.address,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    // Review Images
                    SizedBox(
                      height: 200,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // TODO: Replace the widgets with [List.generate()] and generate
                          // a list of _imageContainers()
                          _imageContainer('toilet'),
                          const SizedBox(
                            width: 20,
                          ),
                          _imageContainer('urinals'),
                          const SizedBox(
                            width: 20,
                          ),
                          _imageContainer('sink'),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        hasRatings
                            ? Row(
                                children: [
                                  // Ratings
                                  _ratingStarsWidget(avgRating!, 25),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  _displayAverageRatings(),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  // Accessibilty Icon
                                  widget.restroom.isAccessible
                                      ? const Icon(
                                          Icons.accessible_forward,
                                          size: 20,
                                        )
                                      : const SizedBox(),
                                ],
                              )
                            : const Text(
                                'There are no ratings for this restroom yet.'),
                        // Distance and Time
                        Text(
                          '${widget.distance} mi, ${widget.time} min',
                          textAlign: TextAlign.end,
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 15,
                    ),

                    // Reviews
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reviews',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        IconButton(
                            onPressed: () {
                              if (signedIn) {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => ReviewPage(
                                    restroom: widget.restroom,
                                  ),
                                );
                              } else {
                                showMessage(
                                    'You have to be signed in to leave a review.');
                              }
                            },
                            icon: const Icon(Icons.add)),
                      ],
                    ),

                    hasReviews
                        ? _reviewListWidget()
                        : const Text(
                            'There are no reviews for this restroom yet.',
                            textAlign: TextAlign.center,
                          ),

                    const SizedBox(
                      height: 15,
                    ),

                    // Get Directions Button
                    ElevatedButton(
                      onPressed: widget.onPressed,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorLight),
                      child: const Text('Get Directions'),
                    )
                  ],
                ),
              ),
            ])));
  }

  Widget _imageContainer(String picture) {
    return SizedBox(
      height: 200,
      width: 200,
      child: Image(
        image: AssetImage('assets/images/$picture.jpg'),
        width: 200,
        height: 200,
      ),
    );
  }

  Widget _ratingStarsWidget(double rating, double size) {
    return Row(
      children: List.generate(5, (index) => _buildStar(index, rating, size)),
    );
  }

  Widget _buildStar(int index, double rating, double size) {
    if (index >= rating) {
      return Icon(
        Icons.star_border,
        color: Colors.amber,
        size: size,
      );
    } else if (index > rating - 1 && index < rating) {
      return Icon(
        Icons.star_half,
        color: Colors.amber,
        size: size,
      );
    } else {
      return Icon(
        Icons.star,
        color: Colors.amber,
        size: size,
      );
    }
  }

  Widget _reviewListWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
          widget.restroom.reviews!.length, (index) => _buildReviewList(index)),
    );
  }

  Widget _buildReviewList(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ratingStarsWidget(widget.restroom.reviews![index].rating, 15),
            const SizedBox(
              width: 5,
            ),
            Text(
              widget.restroom.reviews![index].timestamp
                  .toDate()
                  .toString()
                  .substring(
                      0,
                      widget.restroom.reviews![index].timestamp
                              .toDate()
                              .toString()
                              .length -
                          10),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              '${widget.restroom.reviews![index].displayName}: ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '"${widget.restroom.reviews![index].review}"',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _displayAverageRatings() {
    _setAverage();
    return Text('$avgRating/5 (${widget.restroom.ratings!.length})');
  }

  void _setAverage() {
    setState(() {
      if (widget.restroom.ratings != null) {
        avgRating =
            double.parse(_average(widget.restroom.ratings!).toStringAsFixed(1));
      }
    });
  }

  double _average(List<double> nums) {
    double avg = 0.0;
    for (double num in nums) {
      avg += num;
    }

    return avg / nums.length;
  }

  void showMessage(String message) {
    final SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
