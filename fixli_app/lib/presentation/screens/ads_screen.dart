// lib/presentation/screens/ads_screen.dart

import 'dart:io'; // 🟢 Ny import
import 'package:fixli_app/presentation/providers/ad_provider.dart';
import 'package:fixli_app/presentation/providers/auth_provider.dart';
import 'package:fixli_app/presentation/screens/category_detail_screen.dart';
import 'package:fixli_app/presentation/screens/map_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // 🟢 Ny import

class AdCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String imagePath;
  const AdCategory(this.name, this.icon, this.color, this.imagePath);
}

final List<AdCategory> adCategories = [
  const AdCategory('Snickeri & Bygg', Icons.carpenter_outlined, Colors.brown, 'assets/Snickeri & Bygg.png'),
  const AdCategory('El & Installation', Icons.electrical_services_outlined, Colors.orange, 'assets/El & Installation.png'),
  const AdCategory('Rörmokeri & VVS', Icons.plumbing_outlined, Colors.blue, 'assets/Rörmokeri & VVS.png'),
  const AdCategory('Städ & Hemvård', Icons.cleaning_services_outlined, Colors.lightBlue, 'assets/Städ & Hemvård.png'),
  const AdCategory('Måleri & Tapetsering', Icons.format_paint_outlined, Colors.purple, 'assets/Måleri & Tapetsering.png'),
  const AdCategory('Trädgård & Utemiljö', Icons.grass_outlined, Colors.green, 'assets/Trädgård & Utemiljö.png'),
  const AdCategory('Flytt & Transport', Icons.local_shipping_outlined, Colors.indigo, 'assets/Flytt & Transport.png'),
  const AdCategory('IT-support & Teknikhjälp', Icons.computer_outlined, Colors.deepPurple, 'assets/IT-support & Teknikhjälp.png'),
  const AdCategory('Montering & Ihopsättning', Icons.build_outlined, Colors.blueGrey, 'assets/Montering & Ihopsättning.png'),
  const AdCategory('Fordon & Maskin', Icons.car_repair_outlined, Colors.blueGrey, 'assets/Fordon & Maskin.png'),
  const AdCategory('Djur & Husdjurspassning', Icons.pets_outlined, Colors.deepOrange, 'assets/Djur & Husdjurspassning.png'),
  const AdCategory('Läxhjälp & Lektioner', Icons.school_outlined, Colors.indigoAccent, 'assets/Läxhjälp & Lektioner.png'),
  const AdCategory('Diverse & Övriga tjänster', Icons.more_horiz_outlined, Colors.grey, 'assets/Diverse & Övriga tjänster.png'),
];

class AdsScreen extends ConsumerStatefulWidget {
  const AdsScreen({super.key});

  @override
  ConsumerState<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends ConsumerState<AdsScreen> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final cityController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  String? selectedCategory;
  double? _selectedLatitude;
  double? _selectedLongitude;
  File? _selectedLogo; // 🟢 Ny state-variabel för logotypen

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    cityController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker(StateSetter setDialogState) async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (ctx) => const MapPickerScreen()),
    );
    if (result != null) {
      setDialogState(() {
        cityController.text = result.address;
        _selectedLatitude = result.coordinates.latitude;
        _selectedLongitude = result.coordinates.longitude;
      });
    }
  }

  // 🟢 Ny metod för att välja logotyp
  Future<void> _pickLogo(StateSetter setDialogState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 400);
    if (pickedFile != null) {
      setDialogState(() {
        _selectedLogo = File(pickedFile.path);
      });
    }
  }

  void _showAddAdDialog() {
    titleController.clear();
    bodyController.clear();
    cityController.clear();
    emailController.clear();
    phoneController.clear();
    _selectedLatitude = null;
    _selectedLongitude = null;
    _selectedLogo = null;
    selectedCategory = adCategories.first.name;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Skapa ny annons'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🟢 Ny sektion för att ladda upp logotyp
                  Center(
                    child: GestureDetector(
                      onTap: () => _pickLogo(setDialogState),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: _selectedLogo != null ? FileImage(_selectedLogo!) : null,
                        child: _selectedLogo == null ? const Icon(Icons.add_a_photo_outlined, size: 30) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(child: Text('Ladda upp logotyp')),
                  const SizedBox(height: 16),

                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titel')),
                  const SizedBox(height: 8),
                  TextField(controller: bodyController, decoration: const InputDecoration(labelText: 'Beskrivning')),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: cityController,
                    readOnly: true,
                    onTap: () => _openMapPicker(setDialogState),
                    decoration: const InputDecoration(labelText: 'Plats', suffixIcon: Icon(Icons.map_outlined)),
                    validator: (val) => (val?.isEmpty ?? true) ? 'Du måste välja en plats' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: adCategories.map((category) {
                      return DropdownMenuItem(value: category.name, child: Text(category.name));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value;
                      });
                    },
                    validator: (value) => value == null ? 'Välj en kategori' : null,
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-post (valfri)')),
                  const SizedBox(height: 8),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefon (valfri)')),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Avbryt')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  bodyController.text.isNotEmpty &&
                  cityController.text.isNotEmpty &&
                  selectedCategory != null) {
                ref.read(adListProvider.notifier).addAd(
                  title: titleController.text,
                  body: bodyController.text,
                  city: cityController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  category: selectedCategory!,
                  latitude: _selectedLatitude,
                  longitude: _selectedLongitude,
                  logoFile: _selectedLogo, // 🟢 Skickar med den valda logotypen
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Spara'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = (user?.name.toLowerCase() == 'admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utforska tjänster'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: _showAddAdDialog,
        tooltip: 'Skapa ny annons',
        child: const Icon(Icons.add),
      )
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24), // Nytt tomrum ovanför texten
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Hitta proffs för alla dina projekt. Utforska våra utvalda företag som erbjuder tjänster inom olika områden.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Alla tjänster',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: adCategories.length,
                itemBuilder: (context, index) {
                  final category = adCategories[index];
                  return _CategoryListItem(category: category);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryListItem extends ConsumerWidget {
  final AdCategory category;
  const _CategoryListItem({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryDetailScreen(categoryName: category.name),
            ),
          );
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(category.imagePath),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4),
                BlendMode.darken,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}