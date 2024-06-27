import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/marker_model.dart';

class MapController extends ChangeNotifier {
  final LatLng _initialCenter = const LatLng(-33.86, 151.20);
  LatLng _center;
  String? _errorMessage;
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> markers = {};
  final Map<MarkerId, String> markerInfo = {};

  LatLng get center => _center;
  String? get errorMessage => _errorMessage;

  MapController() : _center = const LatLng(-33.86, 151.20) {
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _center = LatLng(position.latitude, position.longitude);

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(_center));

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void onLongPress(LatLng latLng, BuildContext context) {
    final markerId = MarkerId(latLng.toString());
    markers.add(Marker(
      markerId: markerId,
      position: latLng,
      onTap: () => _onMarkerTapped(markerId, context),
    ));
    _showAddMarkerDialog(markerId, context);
    notifyListeners();
  }

  void _onMarkerTapped(MarkerId markerId, BuildContext context) {
    final info = markerInfo[markerId] ?? '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Marker Info'),
          content: Text(info),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                markers.removeWhere((marker) => marker.markerId == markerId);
                markerInfo.remove(markerId);
                notifyListeners();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddMarkerDialog(MarkerId markerId, BuildContext context) {
    final textEditingController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Marker Info'),
          content: TextField(
            controller: textEditingController,
            decoration: const InputDecoration(hintText: 'Enter marker info'),
          ),
          actions: [
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                markerInfo[markerId] = textEditingController.text;
                notifyListeners();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
