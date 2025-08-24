import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initialLocation;
  const MapPickerPage({super.key, this.initialLocation});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? pickedLocation;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    pickedLocation = widget.initialLocation ?? LatLng(2.0469, 45.3182); // Default: Mogadishu
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      pickedLocation = pos;
    });
  }

  void _onConfirm() {
    if (pickedLocation != null) {
      Navigator.of(context).pop(pickedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Pick Location'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
      Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SvgPicture.asset(
        'assets/icons/iibsasho Logo.svg',
              height: 32,
              width: 32,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pickedLocation!,
              zoom: 14,
            ),
            onMapCreated: (controller) => mapController = controller,
            onTap: _onMapTap,
            markers: pickedLocation != null
                ? {
                    Marker(
                      markerId: MarkerId('picked'),
                      position: pickedLocation!,
                    ),
                  }
                : {},
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _onConfirm,
              child: Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }
}
