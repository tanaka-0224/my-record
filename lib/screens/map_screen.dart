import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/map_controller.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mapController = Provider.of<MapController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps Sample App'),
        backgroundColor: Colors.green[700],
      ),
      body: mapController.errorMessage != null
          ? Center(child: Text('Error: ${mapController.errorMessage}'))
          : GoogleMap(
              onMapCreated: mapController.onMapCreated,
              initialCameraPosition: CameraPosition(
                target: mapController.center,
                zoom: 15.0,
              ),
              markers: mapController.markers,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          mapController.addMarkerAtCurrentLocation(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
