import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
    _init();
  }

  void _init() {
    _updateCurrentPosition(); // 初回の位置更新
    Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateCurrentPosition(); // 10秒ごとに位置を更新
    });
  }

  Future<void> _updateCurrentPosition() async {
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

  Future<void> addMarkerAtCurrentLocation(BuildContext context) async {
    final BitmapDescriptor? selectedIcon =
        await _showIconSelectionDialog(context);
    if (selectedIcon != null) {
      final markerId = MarkerId(_center.toString());
      markers.add(Marker(
        markerId: markerId,
        position: _center,
        icon: selectedIcon,
        onTap: () => _onMarkerTapped(markerId, context),
      ));
      _showAddMarkerDialog(markerId, context);
      notifyListeners();
    }
  }

  Future<BitmapDescriptor?> _showIconSelectionDialog(
      BuildContext context) async {
    return showDialog<BitmapDescriptor>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Marker Icon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Image.asset('assets/images/3678.png',
                    width: 48, height: 48),
                title: const Text('Icon 1'),
                onTap: () async {
                  final icon = await BitmapDescriptor.fromAssetImage(
                    const ImageConfiguration(size: Size(48, 48)),
                    'assets/images/3678.png',
                  );
                  Navigator.of(context).pop(icon);
                },
              ),
              ListTile(
                leading: Image.asset('assets/images/restaurant.png',
                    width: 48, height: 48),
                title: const Text('Icon 1'),
                onTap: () async {
                  final icon = await BitmapDescriptor.fromAssetImage(
                    const ImageConfiguration(size: Size(48, 48)),
                    'assets/images/restaurant.png',
                  );
                  Navigator.of(context).pop(icon);
                },
              ),
              // 他のアイコンも同様に追加
            ],
          ),
        );
      },
    );
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
