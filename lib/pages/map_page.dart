import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_map_demo/consts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  static const _pRoom = LatLng(10.781428881466075, 106.64084249703329);
  static const _pSchool = LatLng(10.768557458769541, 106.68309453411955);

  LatLng? _currentPosition = null;

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();

    getLocationUpdates().then((_) => {
          getPolylinePoints().then((coordinates) => {
                generatePolylineFromPoints(coordinates),
              }),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _currentPosition == null
            ? const Center(child: Text("Loading..."))
            : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController.complete(controller);
                  },
                  initialCameraPosition: CameraPosition(
                    target: _pRoom!,
                    zoom: 13,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('currentPosition'),
                      position: _currentPosition!,
                      icon: BitmapDescriptor.defaultMarker,
                    ),
                    Marker(
                      markerId: const MarkerId('sourcePosition'),
                      position: _pRoom,
                      icon: BitmapDescriptor.defaultMarker,
                    ),
                    Marker(
                      markerId: const MarkerId('destinationPosition'),
                      position: _pSchool,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueViolet),
                    ),
                  },
                  polylines: Set<Polyline>.of(polylines.values),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: ElevatedButton(
                    onPressed: () {
                      _cameraToPositoon(_currentPosition!);
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ));
  }

  Future<void> _cameraToPositoon(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: position,
      zoom: 13,
    )));
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    _serviceEnabled = await _locationController.serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          // _cameraToPositoon(_currentPosition!);
        });
      }
    });
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGLE_API_KEY,
      PointLatLng(_pRoom.latitude, _pRoom.longitude),
      PointLatLng(_pSchool.latitude, _pSchool.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }

    return polylineCoordinates;
  }

  void generatePolylineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 8,
    );

    setState(() {
      polylines[id] = polyline;
    });
  }
}
