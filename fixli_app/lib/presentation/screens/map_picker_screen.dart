// lib/presentation/screens/map_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class PickedLocation {
  final String address;
  final LatLng coordinates;
  PickedLocation({required this.address, required this.coordinates});
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});
  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _initialPosition = LatLng(56.1982, 12.5649);

  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  String _selectedAddress = 'Tryck på kartan för att välja en plats...';
  bool _isLoadingAddress = false;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _selectLocation(LatLng position) async {
    setState(() {
      _pickedLocation = position;
      _isLoadingAddress = true;
      _selectedAddress = 'Hämtar adress...';
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'sv_SE',
      );

      if (mounted && placemarks.isNotEmpty) {
        final p = placemarks.first;
        final street = p.street ?? '';
        final postalCode = p.postalCode ?? '';
        String city = p.locality ?? '';
        if (city.isEmpty) { city = p.subAdministrativeArea ?? ''; }
        if (city.isEmpty) { city = p.subLocality ?? ''; }
        final cityLine = '$postalCode $city'.trim();
        final fullAddress = [street, cityLine].where((part) => part.isNotEmpty).join(', ');
        setState(() {
          _selectedAddress = fullAddress.isEmpty ? 'Kunde inte hitta adressen' : fullAddress;
        });
      }
    } catch (e) {
      if(mounted) { setState(() { _selectedAddress = 'Kunde inte hitta adressen.'; }); }
    } finally {
      if(mounted) { setState(() { _isLoadingAddress = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Välj plats på kartan'),
        actions: [
          if (_pickedLocation != null && !_isLoadingAddress)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Välj denna plats',
              onPressed: () => Navigator.of(context).pop(
                PickedLocation(
                  address: _selectedAddress,
                  coordinates: _pickedLocation!,
                ),
              ),
            )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(target: _initialPosition, zoom: 12.0),
            onTap: _selectLocation,
            markers: _pickedLocation == null ? {} : { Marker(markerId: const MarkerId('m1'), position: _pickedLocation!) },
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _selectedAddress,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}