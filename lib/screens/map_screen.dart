import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:my_record/controllers/map_controller.dart';

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapController(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Map Screen'),
        ),
        body: Consumer<MapController>(
          builder: (context, mapController, child) {
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: mapController.center,
                zoom: 14.0,
              ),
              onMapCreated: mapController.onMapCreated,
              markers: mapController.markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            );
          },
        ),
        floatingActionButton: Consumer<MapController>(
          builder: (context, mapController, child) {
            return FloatingActionButton(
              onPressed: () =>
                  mapController.addMarkerAtCurrentLocation(context),
              child: const Icon(Icons.add_location),
            );
          },
        ),
      ),
    );
  }
}
