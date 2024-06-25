// marker_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:my_record/app_state.dart';
import 'package:provider/provider.dart';

class MarkerDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);
    final markerId = MarkerId(appState.center.toString());

    return AlertDialog(
      title: Text('Add Marker Info'),
      content: TextField(
        controller: TextEditingController(),
        decoration: InputDecoration(hintText: 'Enter marker info'),
      ),
      actions: [
        TextButton(
          child: Text('Save'),
          onPressed: () {
            appState.markerInfo[markerId] = '';
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
  }
}
