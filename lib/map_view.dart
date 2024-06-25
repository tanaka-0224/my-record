// map_view.dart
import 'package:flutter/material.dart';
import 'package:my_record/app_state.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps Sample App'),
        backgroundColor: Colors.green[700],
      ),
      body: appState.errorMessage != null
          ? Center(child: Text('Error: ${appState.errorMessage}'))
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                appState.controller.complete(controller);
              },
              initialCameraPosition: CameraPosition(
                target: appState.center,
                zoom: 15.0,
              ),
              markers: appState.markers,
              onLongPress: (latLng) => appState.onLongPress(latLng),
            ),
    );
  }
}
