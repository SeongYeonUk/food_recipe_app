import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:food_recipe_app/services/home_geofence.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _selectedLocation;
  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(37.5665, 126.9780), // 서울 시청 기본 위치
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

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _saveHomeLocation() {
    if (_selectedLocation != null) {
      HomeGeofence.setHome(_selectedLocation!.latitude, _selectedLocation!.longitude);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('집 위치가 저장되었습니다!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('집 위치 설정'),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveHomeLocation,
              tooltip: '저장',
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
                      ? '지도를 탭하여 집 위치를 선택하세요.'
                      : '선택된 위치를 저장하려면 우측 상단 체크 버튼을 누르세요.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToCurrentLocation,
        tooltip: '현재 위치로 이동',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
