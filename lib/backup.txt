import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() =>
    runApp(const MaterialApp(home: MyApp())); // MyApp を MaterialApp でラップ

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LatLng _initialCenter = const LatLng(-33.86, 151.20);
  late LatLng _center;
  String? _errorMessage;
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> markers = {};
  final Map<MarkerId, String> markerInfo = {}; // マーカー情報を保持するマップ

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });

      print('Current Position: $position');
      print('Current Position: $_center'); // ここで _center の値を出力

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(_center));
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void onLongPress(LatLng latLng) {
    final markerId = MarkerId(latLng.toString());
    setState(() {
      markers.add(Marker(
        markerId: markerId,
        position: latLng,
        onTap: () => _onMarkerTapped(markerId),
      ));
    });
    _showAddMarkerDialog(markerId);
  }

  void _onMarkerTapped(MarkerId markerId) {
    final info = markerInfo[markerId] ?? '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Marker Info'),
          content: Text(info),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                setState(() {
                  markers.removeWhere((marker) => marker.markerId == markerId);
                  markerInfo.remove(markerId);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddMarkerDialog(MarkerId markerId) {
    final TextEditingController textEditingController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Marker Info'),
          content: TextField(
            controller: textEditingController,
            decoration: InputDecoration(hintText: 'Enter marker info'),
          ),
          actions: [
            TextButton(
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  markerInfo[markerId] = textEditingController.text;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps Sample App'),
        backgroundColor: Colors.green[700],
      ),
      body: _errorMessage != null
          ? Center(child: Text('Error: $_errorMessage'))
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 15.0,
              ),
              markers: markers,
              onLongPress: onLongPress,
            ),
    );
  }
}
