import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initialLocation;
  const MapPickerPage({super.key, this.initialLocation});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? pickedLocation;

  @override
  void initState() {
    super.initState();
    pickedLocation = widget.initialLocation ?? LatLng(2.0469, 45.3182); // Default: Mogadishu
  }

  void _onMapTap(LatLng pos) {
    setState(() => pickedLocation = pos);
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
          if (pickedLocation != null)
            FlutterMap(
              options: MapOptions(
                initialCenter: pickedLocation!,
                initialZoom: 14,
                onTap: (tapPosition, point) => _onMapTap(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.iibsasho.app',
                ),
                if (pickedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pickedLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                      ),
                    ],
                  ),
              ],
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
