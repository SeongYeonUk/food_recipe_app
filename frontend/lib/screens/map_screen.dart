// dart
// 파일: lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/home_geofence.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Marker? _homeMarker;
  LatLng _initial = LatLng(37.5665, 126.9780);

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future _loadHome() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('home_lat');
    final lng = prefs.getDouble('home_lng');
    if (lat != null && lng != null) {
      setState(() {
        _homeMarker = Marker(
          markerId: const MarkerId('home'),
          position: LatLng(lat, lng),
          infoWindow: const InfoWindow(title: '집'),
        );
        _initial = LatLng(lat, lng);
      });
    }
  }

  Future _onLongPress(LatLng pos) async {
    await HomeGeofence.setHome(pos.latitude, pos.longitude);
    await HomeGeofence.startMonitoring();
    setState(() {
      _homeMarker = Marker(
        markerId: const MarkerId('home'),
        position: pos,
        infoWindow: const InfoWindow(title: '집'),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('집 위치가 설정되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('집 위치 설정')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _initial, zoom: 15),
        onMapCreated: (c) => _controller = c,
        markers: _homeMarker != null ? {_homeMarker!} : {},
        onLongPress: _onLongPress,
        myLocationEnabled: true,
      ),
    );
  }
}
