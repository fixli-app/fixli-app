// lib/presentation/screens/create_request_screen.dart

import 'dart:io';
import 'package:fixli_app/presentation/providers/auth_provider.dart';
import 'package:fixli_app/presentation/providers/request_provider.dart';
import 'package:fixli_app/presentation/screens/map_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});
  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactPrefController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    _contactPrefController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 365)), locale: const Locale('sv', 'SE'));
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (pickedTime == null) return;
    final fullDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    _timeController.text = DateFormat('yyyy-MM-dd HH:mm', 'sv_SE').format(fullDateTime);
  }

  Future<void> _openMapPicker() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (ctx) => const MapPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _locationController.text = result.address;
        _selectedLatitude = result.coordinates.latitude;
        _selectedLongitude = result.coordinates.longitude;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (pickedFile != null) {
      setState(() { _selectedImage = File(pickedFile.path); });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) { return; }
      final success = await ref.read(requestListProvider.notifier).addRequest(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        time: _timeController.text.trim(),
        price: _priceController.text.trim(),
        userId: userId,
        body: _bodyController.text.trim(),
        contactPreference: _contactPrefController.text.trim(),
        imageFile: _selectedImage,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
      );
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uppdraget har skapats!'), backgroundColor: Colors.green));
      } else if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kunde inte skapa uppdraget.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skapa ett nytt uppdrag')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedImage != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover)),
                    IconButton(icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)), onPressed: () => setState(() => _selectedImage = null))
                  ],
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Välj en bild för uppdraget (valfritt)'),
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 24), side: BorderSide(color: Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              const SizedBox(height: 24),
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titel (kort, ex: "Montera TV")'), validator: (val) => (val?.isEmpty ?? true) ? 'Fältet får inte vara tomt' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _bodyController, decoration: const InputDecoration(labelText: 'Beskrivning (Vilken hjälp du söker eller erbjuder?)'), maxLines: 4, validator: (val) => (val?.isEmpty ?? true) ? 'Fältet får inte vara tomt' : null),
              const SizedBox(height: 15),
              TextFormField(
                controller: _locationController,
                readOnly: true,
                onTap: _openMapPicker,
                decoration: const InputDecoration(labelText: 'Plats', suffixIcon: Icon(Icons.map_outlined)),
                validator: (val) => (val?.isEmpty ?? true) ? 'Du måste välja en plats' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(controller: _timeController, readOnly: true, onTap: _pickDateTime, decoration: const InputDecoration(labelText: 'När? (datum och tid)', suffixIcon: Icon(Icons.calendar_month_outlined)), validator: (val) => (val?.isEmpty ?? true) ? 'Välj en tidpunkt' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Vad erbjuder du? (ex: 100 kr)'), keyboardType: TextInputType.number, validator: (val) => (val?.isEmpty ?? true) ? 'Fältet får inte vara tomt' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _contactPrefController, decoration: const InputDecoration(labelText: 'Kontaktönskemål (ex: "Ring efter 17")')),
              const SizedBox(height: 25),
              ElevatedButton(onPressed: _submit, child: const Text('Lägg upp uppdrag')),
            ],
          ),
        ),
      ),
    );
  }
}