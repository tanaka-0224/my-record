import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class MapController extends ChangeNotifier {
  LatLng _center;
  String? _errorMessage;
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> markers = {};
  final Map<MarkerId, String> markerInfo = {};
  final Map<MarkerId, String> markerIconPaths = {};

  LatLng get center => _center;
  String? get errorMessage => _errorMessage;

  MapController(BuildContext context) : _center = const LatLng(-33.86, 151.20) {
    _init(context);
  }

  Future<void> _init(BuildContext context) async {
    await _loadMarkers(context);
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
      await _saveMarkers();
      notifyListeners();
    }
  }

  Future<BitmapDescriptor?> _showIconSelectionDialog(
      BuildContext context) async {
    final ImagePicker _picker = ImagePicker(); // ImagePickerのインスタンスを作成

    return showDialog<BitmapDescriptor>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Marker Icon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.location_on, size: 48),
                title: const Text('Default Icon'),
                onTap: () async {
                  final icon = BitmapDescriptor.defaultMarker;
                  Navigator.of(context).pop(icon);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, size: 48),
                title: const Text('Choose from Photos'),
                onTap: () async {
                  final XFile? photo =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (photo != null) {
                    final savedPath = await _saveImageToFileSystem(photo.path);
                    final bytes = await _resizeAndConvertToBytes(savedPath);
                    final icon = BitmapDescriptor.fromBytes(bytes);
                    markerIconPaths[MarkerId(_center.toString())] = savedPath;
                    Navigator.of(context).pop(icon);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _saveImageToFileSystem(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = imagePath.split('/').last;
    final savedPath = '${directory.path}/$fileName';
    await File(imagePath).copy(savedPath);
    return savedPath;
  }

  Future<Uint8List> _resizeAndConvertToBytes(String imagePath) async {
    final File imageFile = File(imagePath);
    final img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
    final img.Image resizedImage =
        img.copyResize(image!, width: 50, height: 50);
    return Uint8List.fromList(img.encodePng(resizedImage));
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
              onPressed: () async {
                markers.removeWhere((marker) => marker.markerId == markerId);
                markerInfo.remove(markerId);
                markerIconPaths.remove(markerId);
                await _saveMarkers(); // Save markers after deletion
                notifyListeners();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddMarkerDialog(
      MarkerId markerId, BuildContext context) async {
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
              onPressed: () async {
                markerInfo[markerId] = textEditingController.text;
                await _saveMarkers(); // Save marker info
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

  Future<void> _saveMarkers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> markerList = markers.map((marker) {
      return jsonEncode({
        'markerId': marker.markerId.value,
        'position': {
          'latitude': marker.position.latitude,
          'longitude': marker.position.longitude,
        },
        'info': markerInfo[marker.markerId] ?? '',
        'iconPath': markerIconPaths[marker.markerId] ?? '',
      });
    }).toList();
    await prefs.setStringList('markers', markerList);
    print('Markers saved: $markerList'); // デバッグコンソールに出力
  }

  Future<void> _loadMarkers(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? markerList = prefs.getStringList('markers');
    if (markerList != null) {
      for (final String markerString in markerList) {
        final Map<String, dynamic> markerMap = jsonDecode(markerString);
        final MarkerId markerId = MarkerId(markerMap['markerId']);
        final LatLng position = LatLng(
          markerMap['position']['latitude'],
          markerMap['position']['longitude'],
        );
        final String info = markerMap['info'];
        final String iconPath = markerMap['iconPath']; // アイコンのパスを取得
        BitmapDescriptor icon = BitmapDescriptor.defaultMarker;

        if (iconPath.isNotEmpty) {
          final bytes = await _resizeAndConvertToBytes(iconPath);
          icon = BitmapDescriptor.fromBytes(bytes);
        } else {
          icon = BitmapDescriptor.defaultMarker; // デフォルトのマーカーアイコン
        }

        markers.add(Marker(
          markerId: markerId,
          position: position,
          icon: icon,
          onTap: () => _onMarkerTapped(markerId, context), // contextを追加
        ));
        markerInfo[markerId] = info;
        markerIconPaths[markerId] = iconPath;
      }
      print('Markers loaded: $markerList'); // デバッグコンソールに出力
    }
    notifyListeners();
  }
}
