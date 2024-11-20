import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class AddMarker extends StatefulWidget {
  final LatLng position;

  const AddMarker({super.key, required this.position});

  @override
  State<AddMarker> createState() => _AddMarkerState();
}

class _AddMarkerState extends State<AddMarker> {
  TextEditingController placeName = TextEditingController();
  TextEditingController address = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColorLight,
        title: const Text('Add a Restroom Here?'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                  child: Column(
                children: [
                  const SizedBox(
                    height: 15,
                  ),
                  const Text(
                      'Fill out the information and a request will be sent.'),
                  const SizedBox(
                    height: 15,
                  ),
                  TextField(
                    controller: placeName,
                    decoration: InputDecoration(
                        labelText: 'Name of the Place/Restroom',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        )),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  TextField(
                    controller: address,
                    decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        )),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showMessage('Submitted Request');
                    }, // TODO: Replace this with storing the request in a firestore database
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColorLight),
                    child: const Text('Submit Request'),
                  ),
                ],
              )),
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'An confirmation email will be sent to you. Your request should be handled in apporixmately five to seven business days.',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                    textHeightBehavior: TextHeightBehavior(),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showMessage(String message) {
    final SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
