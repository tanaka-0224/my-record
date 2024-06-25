// app_state.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MyAppState extends ChangeNotifier {
  final LatLng _initialCenter = const LatLng(-33.86, 151.20);
  late LatLng _center;
  String? _errorMessage;
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> markers = {};
  final Map<MarkerId, String> markerInfo = {}; // マーカー情報を保持するマップ

  LatLng get center => _center;
  String? get errorMessage => _errorMessage;
  Completer<GoogleMapController> get controller => _controller;

  void init() {
    _center = _initialCenter;
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

      print('Current Position: $position');
      print('Current Position: $_center'); // ここで _center の値を出力

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(_center));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  onLongPress(LatLng latLng) {}
}
