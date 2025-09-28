// lib/presentation/screens/ad_radius_filter_screen.dart

import 'dart:ui' as ui;
import 'package:fixli_app/presentation/providers/ad_provider.dart';
import 'package:fixli_app/presentation/providers/request_provider.dart';
import 'package:fixli_app/presentation/widgets/detail_dialogs.dart'; // 🟢 Ny import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdRadiusFilterScreen extends ConsumerStatefulWidget {
  const AdRadiusFilterScreen({super.key});

  @override
  ConsumerState<AdRadiusFilterScreen> createState() => _AdRadiusFilterScreenState();
}

class _AdRadiusFilterScreenState extends ConsumerState<AdRadiusFilterScreen> {
  static const _initialPosition = LatLng(56.1982, 12.5649);

  LatLng _currentCenter = _initialPosition;
  double _currentRadiusKm = 10.0;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

  BitmapDescriptor? _adMarkerIcon;

  @override
  void initState() {
    super.initState();
    _currentCenter = ref.read(adRadiusCenterProvider) ?? _initialPosition;
    _currentRadiusKm = ref.read(adRadiusDistanceProvider);
    _updateCircle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildMarkers();
    });
  }

  Future<void> _buildMarkers() async {
    _adMarkerIcon ??= await _createCustomPinMarker(Colors.blueAccent.shade700);

    final allItems = ref.read(mappableItemsProvider);
    final Set<Marker> markers = {};

    final sponsoredItems = allItems.where((item) => item.isSponsored).toList();

    for (final item in sponsoredItems) {
      markers.add(
        Marker(
          markerId: MarkerId('ad_${item.id}'),
          position: item.position,
          icon: _adMarkerIcon!,
          infoWindow: InfoWindow(
            title: item.title,
            snippet: 'Tryck här för att se detaljer',
            // 🟢 HÄR ÄR DEN NYA FUNKTIONEN
            onTap: () {
              // Hitta den fullständiga annonsen
              final allAds = ref.read(adListProvider).asData?.value ?? [];
              final targetAd = allAds.firstWhere(
                    (ad) => ad.id == item.id,
                // orElse är en säkerhetsåtgärd
                orElse: () => allAds.first,
              );

              // Stäng kartan först
              Navigator.of(context).pop();
              // Visa detaljvyn för annonsen
              showAdDetailDialog(context, targetAd);
            },
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Future<BitmapDescriptor> _createCustomPinMarker(Color color) async {
    final double radius = 25.0;
    final double stemHeight = 40.0;
    final double stemWidth = 8.0;
    final double shadowOffset = 4.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.3);
    canvas.drawOval(Rect.fromLTWH(radius - stemWidth / 2 - shadowOffset / 2, radius + stemHeight - shadowOffset / 2, stemWidth + shadowOffset, shadowOffset * 2), shadowPaint);

    final stemPaint = Paint()..color = Colors.grey.shade600;
    canvas.drawRect(Rect.fromLTWH(radius - stemWidth / 2, radius, stemWidth, stemHeight), stemPaint);

    final circlePaint = Paint()..color = color;
    canvas.drawCircle(Offset(radius, radius), radius, circlePaint);

    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(Offset(radius * 1.3, radius * 0.7), radius * 0.4, highlightPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage((radius * 2).toInt() + stemWidth.toInt(), (radius * 2 + stemHeight).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }


  void _updateCircle() {
    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('radius_circle'),
          center: _currentCenter,
          radius: _currentRadiusKm * 1000,
          fillColor: Colors.teal.withOpacity(0.2),
          strokeColor: Colors.teal,
          strokeWidth: 2,
        )
      };
    });
  }

  void _onCameraMove(CameraPosition position) {
    setState(() { _currentCenter = position.target; });
    _updateCircle();
  }

  void _applyFilter() {
    ref.read(adRadiusCenterProvider.notifier).state = _currentCenter;
    ref.read(adRadiusDistanceProvider.notifier).state = _currentRadiusKm;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtrera på avstånd'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _currentCenter, zoom: 10),
              circles: _circles,
              markers: _markers,
              onCameraMove: _onCameraMove,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.background,
            child: Column(
              children: [
                Text('Sök inom ${_currentRadiusKm.toStringAsFixed(1)} km', style: Theme.of(context).textTheme.titleLarge),
                Slider(
                  value: _currentRadiusKm,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '${_currentRadiusKm.toStringAsFixed(1)} km',
                  onChanged: (value) {
                    setState(() { _currentRadiusKm = value; });
                    _updateCircle();
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    child: const Text('Tillämpa'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}