// ignore_for_file: unused_field, prefer_final_fields

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:loocator/api/distance_matrix_api.dart';
import 'package:loocator/models/restroom.dart';
import 'package:loocator/pages/add_marker.dart';
import 'package:loocator/pages/login_page.dart';
import 'package:loocator/utils/firestore.dart';
import 'package:loocator/utils/utils.dart';
import 'package:loocator/pages/in_route_screen.dart';
import 'package:loocator/pages/info_screen.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  bool userSignedIn = false;

  List<Restroom> restrooms = [];
  List<LatLng> markers = [];

  List<NavigationWaypoint> _waypoints = <NavigationWaypoint>[];

  LatLng? _userLocation;
  static const int _userLocationTimeoutMS = 1500;
  static const LatLng cameraLocationMIT =
      LatLng(latitude: 42.3601, longitude: -71.094013);

  bool _navigatorInitialized = false;

  bool _locationPermissionsAccepted = false;
  bool _termsAndConditionsAccepted = false;

  bool _errorOnSetDestinations = false;
  bool _validRoute = false;
  bool _uiEnabled = false;

  GoogleNavigationViewController? _navigationViewController;
  bool _navigatorInitializedAtLeastOnce = false;

  int _onRoadSnappedLocationUpdatedEventCallCount = 0;
  int _onRoadSnappedRawLocationUpdatedEventCallCount = 0;
  int _onRemainingTimeOrDistanceChangedEventCallCount = 0;
  StreamSubscription<RoadSnappedLocationUpdatedEvent>?
      _roadSnappedLocationUpdatedSubscription;
  StreamSubscription<RoadSnappedRawLocationUpdatedEvent>?
      _roadSnappedRawLocationUpdatedSubscription;
  StreamSubscription<RemainingTimeOrDistanceChangedEvent>?
      _remainingTimeOrDistanceChangedSubscription;

  int _remainingDistance = 0;
  int _remaingingTime = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _askLocationPermissinosIfNeeded();

    await _showTermsAndConditionsDialogIfNeeded();

    if (_locationPermissionsAccepted && _termsAndConditionsAccepted) {
      _initializeNavigator();
    }
  }

  Future<void> _initializeNavigator() async {
    assert(_termsAndConditionsAccepted, 'Terms must be accepted');
    assert(
        _locationPermissionsAccepted, 'Location permissions must be granted');

    if (!_navigatorInitialized) {
      debugPrint('Initializing new navigation session...');
      await GoogleMapsNavigator.initializeNavigationSession();
      await _setupListeners();
      restrooms = await buildRestrooms();
      _buildMarkers();
      await _updateNavigatorInitializationState();
      unawaited(_setDefaultUserLocationAfterDelay());
      debugPrint('Navigator has been initialized: $_navigatorInitialized');
    }
    setState(() {});
  }

  Future<void> _askLocationPermissinosIfNeeded() async {
    _locationPermissionsAccepted = await requestLocationDialogAcceptance();
    setState(() {});
  }

  Future<void> _showTermsAndConditionsDialogIfNeeded() async {
    _termsAndConditionsAccepted = await requestTermsAndConditionsAcceptance();
    setState(() {});
  }

  Future<void> _updateNavigatorInitializationState() async {
    _navigatorInitialized = await GoogleMapsNavigator.isInitialized();
    if (_navigatorInitialized) {
      _navigatorInitializedAtLeastOnce = true;
    }
    setState(() {});
  }

  Future<void> _setDefaultUserLocationAfterDelay() async {
    Future<void>.delayed(const Duration(milliseconds: _userLocationTimeoutMS),
        () async {
      if (mounted && _userLocation == null) {
        _userLocation = await _navigationViewController?.getMyLocation() ??
            cameraLocationMIT;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future<void> _setupListeners() async {
    _clearListeners();
    _roadSnappedLocationUpdatedSubscription =
        await GoogleMapsNavigator.setRoadSnappedLocationUpdatedListener(
            _onRoadSnappedLocationUpdatedEvent);
    _roadSnappedRawLocationUpdatedSubscription =
        await GoogleMapsNavigator.setRoadSnappedRawLocationUpdatedListener(
            _onRoadSnappedRawLocationUpdatedEvent);
    _remainingTimeOrDistanceChangedSubscription =
        GoogleMapsNavigator.setOnRemainingTimeOrDistanceChangedListener(
            _onRemainingTimeOrDistanceChangedEvent,
            remainingDistanceThresholdMeters: 1,
            remainingTimeThresholdSeconds: 1);
  }

  void _clearListeners() {
    _roadSnappedLocationUpdatedSubscription?.cancel();
    _roadSnappedLocationUpdatedSubscription = null;

    _roadSnappedRawLocationUpdatedSubscription?.cancel();
    _roadSnappedRawLocationUpdatedSubscription = null;

    _remainingTimeOrDistanceChangedSubscription?.cancel();
    _remainingTimeOrDistanceChangedSubscription = null;
  }

  void _onRoadSnappedLocationUpdatedEvent(
      RoadSnappedLocationUpdatedEvent event) {
    if (!mounted) {
      return;
    }

    setState(() {
      _userLocation = event.location;
      _onRoadSnappedLocationUpdatedEventCallCount += 1;
    });
  }

  // Note: Raw location updates are not available on iOS.
  void _onRoadSnappedRawLocationUpdatedEvent(
      RoadSnappedRawLocationUpdatedEvent event) {
    if (!mounted) {
      return;
    }

    setState(() {
      _userLocation = event.location;
      _onRoadSnappedRawLocationUpdatedEventCallCount += 1;
    });
  }

  void _onRemainingTimeOrDistanceChangedEvent(
      RemainingTimeOrDistanceChangedEvent event) {
    if (!mounted) {
      return;
    }

    setState(() {
      _remainingDistance = event.remainingDistance.toInt();
      _remaingingTime = event.remainingTime.toInt();
      _onRemainingTimeOrDistanceChangedEventCallCount += 1;
    });
  }

  ///Places predetermined markers in map when the map is creates
  Future<void> _placeMarkers() async {
    for (Restroom marker in restrooms) {
      await _navigationViewController!.addMarkers(
          <MarkerOptions>[MarkerOptions(position: marker.position)]);
    }
  }

  Future<void> _addWaypoint(String marker) async {
    List<Marker?> markers = await _navigationViewController!.getMarkers();

    Marker? waypointMarker;

    for (Marker? m in markers) {
      if (m!.markerId == marker) {
        waypointMarker = m;
      }
    }

    _waypoints.add(NavigationWaypoint(
        title: 'Waypoint ${waypointMarker!.markerId.split('_')[1]}',
        target: LatLng(
            latitude: waypointMarker.options.position.latitude,
            longitude: waypointMarker.options.position.longitude)));
  }

  /// Displays destinations before starting navigation
  Future<void> _displayDestination() async {
    _navigationViewController!.moveCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: _userLocation!, northeast: _waypoints.first.target!),
        padding: 105));
    _updateNavigationDestinations();
  }

  Future<void> _updateNavigationDestinationsAndNavigationViewState() async {
    final bool success = await _updateNavigationDestinations();
    if (success) {
      await _navigationViewController!.setNavigationUIEnabled(true);
    }

    setState(() {
      _validRoute = true;
      _uiEnabled = true;
    });
  }

  Future<bool> _updateNavigationDestinations() async {
    if (_navigationViewController == null || _waypoints.isEmpty) {
      return false;
    }
    if (!_navigatorInitialized) {
      await _initializeNavigator();
    }

    // Build destinations with Routes API
    final Destinations? destinations = _buildDestinations();

    if (destinations == null) {
      setState(() {
        _errorOnSetDestinations = true;
      });
      return false;
    }

    try {
      final NavigationRouteStatus navRouteStatus =
          await GoogleMapsNavigator.setDestinations(destinations);

      switch (navRouteStatus) {
        case NavigationRouteStatus.statusOk:
          // Route is valid. Return true as success.
          setState(() {
            _errorOnSetDestinations = false;
            _validRoute = true;
          });
          return true;
        case NavigationRouteStatus.internalError:
          showMessage(
              'Unexpected internal error occured. Please restart the app.');
        case NavigationRouteStatus.routeNotFound:
          showMessage('The route could not be calculated.');
        case NavigationRouteStatus.networkError:
          showMessage(
              'Working network connection is required to calculate the route.');
        case NavigationRouteStatus.quotaExceeded:
          showMessage('Insufficient API quota to use the navigation.');
        case NavigationRouteStatus.quotaCheckFailed:
          showMessage(
              'API quota check failed, cannot authorize the navigation.');
        case NavigationRouteStatus.apiKeyNotAuthorized:
          showMessage('A valid API key is required to use the navigation.');
        case NavigationRouteStatus.statusCanceled:
          showMessage(
              'The route calculation was canceled in favor of a newer one.');
        case NavigationRouteStatus.duplicateWaypointsError:
          showMessage(
              'The route could not be calculated because of duplicate waypoints.');
        case NavigationRouteStatus.noWaypointsError:
          showMessage(
              'The route could not be calculated because no waypoints were provided.');
        case NavigationRouteStatus.locationUnavailable:
          showMessage(
              'No user location is available. Did you allow location permission?');
        case NavigationRouteStatus.waypointError:
          showMessage('Invalid waypoints provided.');
        case NavigationRouteStatus.travelModeUnsupported:
          showMessage(
              'The route could not calculated for the given travel mode.');
        case NavigationRouteStatus.unknown:
          showMessage(
              'The route could not be calculated due to an unknown error.');
        case NavigationRouteStatus.locationUnknown:
          showMessage(
              'The route could not be calculated, because the user location is unknown.');
      }
    } on RouteTokenMalformedException catch (_) {
      debugPrint('Malformed route token');
    } on SessionNotInitializedException catch (_) {
      debugPrint('Cannot set destinations, session not initialized');
    }
    setState(() {
      _errorOnSetDestinations = true;
    });
    return false;
  }

  /// Build destinations from [_waypoints].
  Destinations? _buildDestinations() {
    // Shows a delayed calculating message
    unawaited(showCalculatingMessage());

    return Destinations(
        waypoints: _waypoints,
        displayOptions: NavigationDisplayOptions(
          showDestinationMarkers: false,
          showStopSigns: true,
          showTrafficLights: true,
        ),
        // Always set travel mode to walking
        routingOptions:
            RoutingOptions(travelMode: NavigationTravelMode.walking));
  }

  @override
  Widget build(BuildContext context) {
    userSignedIn = (FirebaseAuth.instance.currentUser != null);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loocator'),
        backgroundColor: Theme.of(context).primaryColorLight,
        actions: [
          _menu(),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 100,
        width: 100,
        child: !_validRoute
            ? FloatingActionButton(
                onPressed: () {
                  _findNearestRestroom();
                },
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.wc,
                  size: 45,
                ),
              )
            : null,
      ),
      body: _navigatorInitializedAtLeastOnce && _userLocation != null
          ? GoogleMapsNavigationView(
              onViewCreated: _onViewCreated,
              onMarkerClicked: _onMarkerClicked,
              onMapLongClicked: _onMapLongClicked,
              initialNavigationUIEnabledPreference:
                  NavigationUIEnabledPreference.disabled,
              initialCameraPosition: CameraPosition(
                target: _userLocation!,
                zoom: 17,
              ),
              // Controls
              initialZoomControlsEnabled: false,
            )
          : const Center(child: CircularProgressIndicator()),
      bottomSheet: (_validRoute && !_uiEnabled)
          ? _goScreen()
          : (_validRoute && _uiEnabled)
              ? InRouteScreen(
                  onPressed: () {
                    setState(() {
                      _cleanSlate();
                    });
                  },
                  distance: _remainingDistance,
                  time: _remaingingTime,
                )
              : null,
    );
  }

  void _cleanSlate() {
    _validRoute = false;
    _uiEnabled = false;
    _waypoints.clear();
    _navigationViewController!.setNavigationUIEnabled(false);
    _navigationViewController!.moveCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLocation!, zoom: 17)));
    GoogleMapsNavigator.cleanup();
  }

  Future<void> _onViewCreated(GoogleNavigationViewController controller) async {
    _navigationViewController = controller;
    controller.setMyLocationEnabled(true);
    await _placeMarkers();
    // Additional setup can be added here.
  }

  void _onMapLongClicked(LatLng position) {
    if (FirebaseAuth.instance.currentUser != null) {
      showModalBottomSheet(
          context: context,
          builder: (context) => AddMarker(
                position: position,
              ));
    } else {
      showMessage('You have to be signed in to add a request.');
    }
  }

  void _onMarkerClicked(String marker) async {
    Restroom markedRestroom =
        await updateRestroom(restrooms[int.parse(marker.split('_')[1])]);

    showModalBottomSheet(
      context: context,
      builder: (context) => InfoScreen(
        onPressed: () async {
          Navigator.pop(context);
          await _addWaypoint(marker);
          _displayDestination();
        },
        distance: _remainingDistance,
        time: _remaingingTime,
        restroom: markedRestroom,
      ),
    );
  }

  @override
  void dispose() {
    GoogleMapsNavigator.cleanup();
    super.dispose();
  }

  void _findNearestRestroom() async {
    await _addWaypoint(
        'Marker_${await findNearestDestination(_latLngAsString(_userLocation!), _buildDestinationRequest(markers))}');
    await _updateNavigationDestinationsAndNavigationViewState();
  }

  String _buildDestinationRequest(List<LatLng> destinations) {
    String request = "";
    for (LatLng point in destinations) {
      request += "${_latLngAsString(point)}|";
    }
    return request.substring(0, request.length - 2);
  }

  String _latLngAsString(LatLng point) {
    return '${point.latitude},${point.longitude}';
  }

  void showMessage(String message) {
    final SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> showCalculatingMessage() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!_validRoute) {
      showMessage('Calculating the route.');
    }
  }

  Widget _goScreen() {
    return Container(
      color: Theme.of(context).primaryColorLight,
      height: 70,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _cleanSlate();
                  });
                },
                child: const Row(
                  children: [
                    Icon(Icons.cancel),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'Cancel',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                )),
          ),
          const SizedBox(
            width: 15,
          ),
          SizedBox(
            width: 150,
            child: ElevatedButton(
                style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.green)),
                onPressed: () {
                  _navigationViewController!.setNavigationUIEnabled(true);
                  setState(() {
                    _uiEnabled = true;
                    _validRoute = true;
                  });
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'Go',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  Widget _menu() {
    return MenuAnchor(
      menuChildren: <Widget>[
        // TODO: Make this the menu for login, registration, and customer service
        MenuItemButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LoginPage()));
          },
          child: userSignedIn
              ? const Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'Profile',
                    ),
                  ],
                )
              : const Row(
                  children: [
                    Icon(Icons.login),
                    SizedBox(
                      width: 5,
                    ),
                    Text('Log In'),
                  ],
                ),
        ),
      ],
      builder: (_, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.menu),
        );
      },
    );
  }

  void _buildMarkers() {
    for (Restroom room in restrooms) {
      markers.add(LatLng(
          latitude: room.position.latitude,
          longitude: room.position.longitude));
    }
  }
}
