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
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() => _selectedLocation = location);
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    try {
      final results = await locationFromAddress(query);
      if (results.isNotEmpty) {
        final first = results.first;
        final target = LatLng(first.latitude, first.longitude);
        setState(() => _selectedLocation = target);
        final controller = await _controller.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 16.0),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('검색한 위치로 이동했어요.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('검색 결과가 없어요. 다른 키워드로 시도해주세요.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치를 찾을 수 없어요.')),
        );
      }
    }
  }

  void _saveHomeLocation() {
    if (_selectedLocation != null) {
      HomeGeofence.setHome(_selectedLocation!.latitude, _selectedLocation!.longitude);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('집 위치가 저장되었어요.'),
          backgroundColor: Colors.green,
        ),
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
            onMapCreated: (controller) => _controller.complete(controller),
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
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '주소를 입력해주세요',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchAddress,
                        ),
                      ),
                      onSubmitted: (_) => _searchAddress(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedLocation == null
                          ? '지도를 탭해서 위치를 선택해주세요'
                          : '선택한 위치를 확정하려면 오른쪽 상단 체크 버튼을 누르세요.',
                      textAlign: TextAlign.center,
                    ),
                  ],
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
