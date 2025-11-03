import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:food_recipe_app/services/home_geofence.dart';
import 'package:geocoding/geocoding.dart' show locationFromAddress;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _selectedLocation;
  final TextEditingController _searchController = TextEditingController();
  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(37.5665, 126.9780), // ?úÏö∏ ?úÏ≤≠ Í∏∞Î≥∏ ?ÑÏπò
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    final position = await HomeGeofence.getCurrentLocation();
    if (position != null) {
      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16.0,
        ),
      ));
    }
  }

  void _onMapTapped(LatLng location) { setState(() { _selectedLocation = location; }); }

  Future<void> _searchAddress() async { final query = _searchController.text.trim(); if (query.isEmpty) return; try { final results = await locationFromAddress(query); if (results.isNotEmpty) { final first = results.first; final target = LatLng(first.latitude, first.longitude); setState(() { _selectedLocation = target; }); final controller = await _controller.future; await controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16.0),)); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('∞Àªˆ ¿ßƒ°∑Œ ¿Ãµø«ﬂæÓø‰.')), ); } } else { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('∞Àªˆ ∞·∞˙∞° æ¯æÓø‰. ¥Ÿ∏• ≈∞øˆµÂ∑Œ Ω√µµ«ÿ ∫∏ººø‰.')), ); } } } catch (e) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¿ßƒ°∏¶ √£¥¬ ¡ﬂ ø¿∑˘∞° πﬂª˝«ﬂæÓø‰.')), ); } } });
  }

  void _saveHomeLocation() {
    if (_selectedLocation != null) {
      HomeGeofence.setHome(_selectedLocation!.latitude, _selectedLocation!.longitude);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ïß??ÑÏπòÍ∞Ä ?Ä?•Îêò?àÏäµ?àÎã§!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ïß??ÑÏπò ?§Ï†ï'),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveHomeLocation,
              tooltip: '?Ä??,
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kDefaultLocation,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onTap: _onMapTapped,
            markers: _selectedLocation == null
                ? {}
                : {
              Marker(
                markerId: const MarkerId('home_marker'),
                position: _selectedLocation!,
              )
            },
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _selectedLocation == null
                      ? 'ÏßÄ?ÑÎ? ??ïò??Ïß??ÑÏπòÎ•??†ÌÉù?òÏÑ∏??'
                      : '?†ÌÉù???ÑÏπòÎ•??Ä?•Ìïò?§Î©¥ ?∞Ï∏° ?ÅÎã® Ï≤¥ÌÅ¨ Î≤ÑÌäº???ÑÎ•¥?∏Ïöî.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToCurrentLocation,
        tooltip: '?ÑÏû¨ ?ÑÏπòÎ°??¥Îèô',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

