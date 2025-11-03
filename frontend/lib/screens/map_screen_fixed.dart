import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_recipe_app/services/home_geofence.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  LatLng? _lastCameraTarget;

  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(37.5665, 126.9780), // Seoul City Hall
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _moveToSavedOrDefault();
  }

  Future<void> _moveToSavedOrDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('home_lat');
    final lng = prefs.getDouble('home_lng');
    if (lat != null && lng != null) {
      await _centerCamera(LatLng(lat, lng), 16.0);
      return;
    }
    await _moveToPreferredLocation();
    final ctrl = await _controller.future;
    await ctrl.animateCamera(CameraUpdate.newCameraPosition(_kDefaultLocation));
  }

  Future<void> _moveToPreferredLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final mockLat = prefs.getDouble('mock_device_lat');
    final mockLng = prefs.getDouble('mock_device_lng');
    if (mockLat != null && mockLng != null) {
      await _centerCamera(LatLng(mockLat, mockLng), 16.0);
      return;
    }
    await _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    final pos = await HomeGeofence.getCurrentLocation();
    if (!mounted) return;
    if (pos != null) {
      final here = LatLng(pos.latitude, pos.longitude);
      if (_isInKorea(here)) {
        await _centerCamera(here, 16.0);
      }
    }
  }

  bool _isInKorea(LatLng p) {
    return p.latitude >= 33 && p.latitude <= 39 && p.longitude >= 124 && p.longitude <= 132;
  }

  Future<void> _centerCamera(LatLng target, double zoom) async {
    final ctrl = await _controller.future;
    await ctrl.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void _onMapTapped(LatLng location) {
    setState(() => _selectedLocation = location);
  }

  Future<void> _searchAddress() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;
    // Geocoding fallback (less reliable on emulators)
    if (!query.toLowerCase().contains('korea') && !query.toLowerCase().contains('republic of korea')) {
      query = '$query, Republic of Korea';
    }
    try {
      List<geocoding.Location> results = [];
      try {
        results = await geocoding.locationFromAddress(query, localeIdentifier: 'en_US');
      } catch (_) {
        results = await geocoding.locationFromAddress(query);
      }
      if (results.isNotEmpty) {
        final loc = results.first;
        final target = LatLng(loc.latitude, loc.longitude);
        setState(() => _selectedLocation = target);
        await _centerCamera(target, 16.0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Moved to searched location.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No results. Try a more specific query.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to find location.')),
        );
      }
    }
  }

  Future<void> _saveHomeLocation() async {
    if (_selectedLocation == null) return;
    await HomeGeofence.setHome(_selectedLocation!.latitude, _selectedLocation!.longitude);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Home location saved!'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop();
  }

  Future<void> _promptCoords() async {
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter coordinates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitude'), keyboardType: TextInputType.number),
            TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: 'Longitude'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                final lat = double.parse(latCtrl.text.trim());
                final lng = double.parse(lngCtrl.text.trim());
                final target = LatLng(lat, lng);
                setState(() => _selectedLocation = target);
                await _centerCamera(target, 16.0);
                if (mounted) Navigator.of(ctx).pop();
              } catch (_) {}
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Home Location'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'recenter_saved') {
                await _moveToSavedOrDefault();
              } else if (val == 'demo_bucheon') {
                const bucheon = LatLng(37.503, 126.763);
                setState(() => _selectedLocation = bucheon);
                await _centerCamera(bucheon, 16.0);
              } else if (val == 'mock_from_camera') {
                final t = _lastCameraTarget;
                if (t != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('mock_device_lat', t.latitude);
                  await prefs.setDouble('mock_device_lng', t.longitude);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Device location override set.')),
                    );
                  }
                }
              } else if (val == 'clear_mock') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('mock_device_lat');
                await prefs.remove('mock_device_lng');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Device location override cleared.')),
                  );
                }
              } else if (val == 'enter_coords') {
                await _promptCoords();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'recenter_saved', child: Text('Recenter to saved/default')),
              PopupMenuItem(value: 'demo_bucheon', child: Text('Set Bucheon (demo)')),
              PopupMenuItem(value: 'mock_from_camera', child: Text('Use camera as device loc')),
              PopupMenuItem(value: 'clear_mock', child: Text('Clear device loc override')),
              PopupMenuItem(value: 'enter_coords', child: Text('Enter coordinates')),
            ],
          ),
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveHomeLocation,
              tooltip: 'Save',
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
            onCameraMove: (pos) {
              _lastCameraTarget = pos.target;
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
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchAddress(),
                      decoration: const InputDecoration(
                        hintText: 'Search address or place',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchAddress,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _selectedLocation == null
                      ? 'Tap map or search above to select.'
                      : 'Tap the check icon to save as home.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToPreferredLocation,
        tooltip: 'Move to current location',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
