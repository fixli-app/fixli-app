// lib/presentation/screens/edit_request_screen.dart

import 'package:fixli_app/data/repositories/request_repository.dart';
import 'package:fixli_app/presentation/providers/request_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditRequestScreen extends ConsumerStatefulWidget {
  final RequestWithUser requestToEdit;
  const EditRequestScreen({super.key, required this.requestToEdit});

  @override
  ConsumerState<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends ConsumerState<EditRequestScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _contactPrefController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final request = widget.requestToEdit.request;
    _titleController = TextEditingController(text: request.title);
    _bodyController = TextEditingController(text: request.body ?? '');
    _locationController = TextEditingController(text: request.location);
    _priceController = TextEditingController(text: request.price);
    _contactPrefController = TextEditingController(text: request.contactPreference ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _contactPrefController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // 🟢 KORRIGERING: Tog bort den felaktiga "time"-parametern
      final success = await ref.read(requestListProvider.notifier).updateRequest(
        requestId: widget.requestToEdit.request.id,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        location: _locationController.text.trim(),
        price: _priceController.text.trim(),
        contactPreference: _contactPrefController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uppdraget har uppdaterats!'), backgroundColor: Colors.green));
      } else if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kunde inte uppdatera uppdraget.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redigera uppdrag')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titel'), validator: (val) => (val?.isEmpty ?? true) ? 'Fältet får inte vara tomt' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _bodyController, decoration: const InputDecoration(labelText: 'Beskrivning'), maxLines: 4, validator: (val) => (val?.isEmpty ?? true) ? 'Fältet får inte vara tomt' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Plats'), validator: (val) => (val?.isEmpty ?? true) ? 'Fältet får inte vara tomt' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Ersättning'), keyboardType: TextInputType.number, validator: (val) => (val?.isEmpty ?? true) ? 'Fältet får inte vara tomt' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _contactPrefController, decoration: const InputDecoration(labelText: 'Kontaktönskemål')),
              const SizedBox(height: 25),
              ElevatedButton(onPressed: _submit, child: const Text('Spara ändringar')),
            ],
          ),
        ),
      ),
    );
  }
}