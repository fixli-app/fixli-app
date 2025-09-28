// lib/presentation/screens/profile_screen.dart

import 'dart:io';
import 'package:fixli_app/data/repositories/auth_repository.dart';
import 'package:fixli_app/data/repositories/request_repository.dart';
import 'package:fixli_app/presentation/providers/auth_provider.dart';
import 'package:fixli_app/presentation/providers/rating_provider.dart';
import 'package:fixli_app/presentation/providers/request_provider.dart';
import 'package:fixli_app/presentation/screens/edit_request_screen.dart';
import 'package:fixli_app/presentation/widgets/detail_dialogs.dart';
// import 'package:fixli_app/presentation/widgets/empty_state_widget.dart'; // Borttagen
import 'package:fixli_app/presentation/widgets/shimmer_list_placeholder.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _selectedImage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _locationController = TextEditingController(text: user?.location ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 600);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    try {
      final updatedUser = await locator<AuthRepository>().updateUserProfile(
        userId: user.id,
        name: user.name,
        email: user.email,
        newLocation: _locationController.text.trim(),
        newPhone: _phoneController.text.trim(),
        newBio: _bioController.text.trim(),
        newProfilePictureFile: _selectedImage,
        existingProfilePicturePath: user.profilePicturePath,
      );
      ref.read(authProvider.notifier).updateUserState(updatedUser);
      _showSnackBar('Din profil har uppdaterats!', isError: false);
      FocusScope.of(context).unfocus();
      setState(() { _selectedImage = null; });
    } catch (e) {
      _showSnackBar('Kunde inte uppdatera profilen.', isError: true);
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final userId = ref.read(authProvider).user?.id;
    if (newPassword.isEmpty || confirmPassword.isEmpty) { _showSnackBar('Fyll i båda lösenordsfälten.', isError: true); return; }
    if (newPassword.length < 6) { _showSnackBar('Lösenordet måste vara minst 6 tecken.', isError: true); return; }
    if (newPassword != confirmPassword) { _showSnackBar('Lösenorden matchar inte.', isError: true); return; }
    if (userId == null) return;
    try {
      await locator<AuthRepository>().changePassword(userId: userId, newPassword: newPassword);
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      FocusScope.of(context).unfocus();
      await ref.read(authProvider.notifier).logout();
      if(mounted) {
        _showSnackBar('Ditt lösenord har ändrats! Vänligen logga in igen.', isError: false);
      }
    } catch (e) {
      _showSnackBar('Kunde inte byta lösenord.', isError: true);
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    try {
      await locator<RequestRepository>().deleteRequest(requestId);
      ref.invalidate(myRequestsProvider);
      ref.invalidate(requestListProvider);
      ref.invalidate(latestRequestsProvider);
      _showSnackBar('Uppdraget har raderats.', isError: false);
    } catch (e) {
      _showSnackBar('Kunde inte radera uppdraget.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Radera uppdrag'),
        content: const Text('Är du säker på att du vill radera detta uppdrag permanent?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Avbryt')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Radera', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const Scaffold(body: Center(child: Text("Ingen användare inloggad.")));

    ImageProvider? profileImage;
    if (_selectedImage != null) {
      profileImage = FileImage(_selectedImage!);
    } else if (user.profilePicturePath != null) {
      profileImage = FileImage(File(user.profilePicturePath!));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Min Profil')),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: profileImage,
                            child: profileImage == null ? const Icon(Icons.person, size: 50) : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.teal,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(child: Text(user.name, style: Theme.of(context).textTheme.headlineSmall)),
                    const SizedBox(height: 8),
                    Center(
                      child: ref.watch(userRatingProvider(user.id)).when(
                        data: (profile) => _StarRatingDisplay(rating: profile.averageRating.average, count: profile.averageRating.count),
                        loading: () => const SizedBox(height: 20),
                        error: (e, st) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Mina Uppdrag'),
                    Tab(text: 'Mina Jobb'),
                    Tab(text: 'Ansökningar'),
                    Tab(text: 'Omdömen'),
                    Tab(text: 'Inställningar'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _MyRequestsList(onDelete: _deleteRequest, onConfirmDelete: _showDeleteConfirmationDialog),
            _MyFixerJobsList(),
            _MyApplicationsList(),
            _MyReviewsList(userId: user.id),
            _SettingsView(
              locationController: _locationController,
              phoneController: _phoneController,
              bioController: _bioController,
              newPasswordController: _newPasswordController,
              confirmPasswordController: _confirmPasswordController,
              onUpdateProfile: _updateProfile,
              onChangePassword: _changePassword,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  final TextEditingController locationController;
  final TextEditingController phoneController;
  final TextEditingController bioController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onUpdateProfile;
  final VoidCallback onChangePassword;

  const _SettingsView({
    required this.locationController,
    required this.phoneController,
    required this.bioController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.onUpdateProfile,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Redigera profilinformation'),
          const SizedBox(height: 16),
          TextFormField(controller: bioController, decoration: const InputDecoration(labelText: 'Om mig (en kort beskrivning)'), maxLines: 3),
          const SizedBox(height: 10),
          TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Ort')),
          const SizedBox(height: 10),
          TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefon'), keyboardType: TextInputType.phone),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onUpdateProfile, child: const Text('Spara profiländringar'))),

          const SizedBox(height: 30),
          _SectionHeader('Byt lösenord'),
          const SizedBox(height: 16),
          TextField(controller: newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Nytt lösenord')),
          const SizedBox(height: 10),
          TextField(controller: confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Bekräfta nytt lösenord')),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onChangePassword, child: const Text('Byt lösenord'))),
        ],
      ),
    );
  }
}


class _MyRequestsList extends ConsumerWidget {
  final Future<void> Function(String) onDelete;
  final Future<bool> Function() onConfirmDelete;
  const _MyRequestsList({required this.onDelete, required this.onConfirmDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myRequestsAsync = ref.watch(myRequestsProvider);
    return myRequestsAsync.when(
      loading: () => const ShimmerListPlaceholder(),
      error: (e, st) => Text('Fel: $e'),
      data: (requests) {
        if (requests.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Du har inte skapat några uppdrag än.')));
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (ctx, index) {
            final requestWithUser = requests[index];
            final req = requestWithUser.request;
            return Slidable(
              key: ValueKey(req.id),
              endActionPane: ActionPane(
                motion: const StretchMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditRequestScreen(requestToEdit: requestWithUser)));
                    },
                    backgroundColor: Colors.blue, foregroundColor: Colors.white,
                    icon: Icons.edit, label: 'Redigera',
                  ),
                  SlidableAction(
                    onPressed: (context) async {
                      final confirmed = await onConfirmDelete();
                      if (confirmed) {
                        onDelete(req.id);
                      }
                    },
                    backgroundColor: Colors.red, foregroundColor: Colors.white,
                    icon: Icons.delete, label: 'Radera',
                  ),
                ],
              ),
              child: Card(
                child: ListTile(
                  leading: StatusDisplay(status: req.status),
                  title: Text(req.title),
                  subtitle: Text(req.location),
                  onTap: () => showRequestDetailDialog(context, requestWithUser, ref),
                  trailing: const Icon(Icons.swipe_left_outlined, color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MyFixerJobsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myFixerJobsAsync = ref.watch(myFixerJobsProvider);
    return myFixerJobsAsync.when(
      loading: () => const ShimmerListPlaceholder(),
      error: (e, st) => Text('Fel: $e'),
      data: (requests) {
        if (requests.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Du har inte blivit vald till några uppdrag än.')));
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (ctx, index) {
            final requestWithUser = requests[index];
            final req = requestWithUser.request;
            return Card(
              child: ListTile(
                leading: StatusDisplay(status: req.status),
                title: Text(req.title),
                subtitle: Text(req.location),
                onTap: () => showRequestDetailDialog(context, requestWithUser, ref),
              ),
            );
          },
        );
      },
    );
  }
}

class _MyApplicationsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myApplicationsAsync = ref.watch(myApplicationsProvider);
    return myApplicationsAsync.when(
      loading: () => const ShimmerListPlaceholder(),
      error: (e, st) => Text('Fel: $e'),
      data: (requests) {
        if (requests.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Du har inte ansökt till några uppdrag än.')));
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (ctx, index) {
            final requestWithUser = requests[index];
            final req = requestWithUser.request;
            return Card(
              child: ListTile(
                leading: StatusDisplay(status: req.status),
                title: Text(req.title),
                subtitle: Text(req.location),
                onTap: () => showRequestDetailDialog(context, requestWithUser, ref),
              ),
            );
          },
        );
      },
    );
  }
}

class _MyReviewsList extends ConsumerWidget {
  final int userId;
  const _MyReviewsList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingProfileAsync = ref.watch(userRatingProvider(userId));
    return ratingProfileAsync.when(
      loading: () => const ShimmerListPlaceholder(itemCount: 3),
      error: (e, st) => const Text('Kunde inte ladda omdömen.'),
      data: (profile) {
        if (profile.allRatings.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Du har inte fått några omdömen än.')));
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: profile.allRatings.length,
          itemBuilder: (ctx, index) {
            final ratingDetails = profile.allRatings[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(child: Text(ratingDetails.rater.name.substring(0, 1).toUpperCase())),
                  title: Text('"${ratingDetails.rating.comment ?? 'Inget omdöme'}"'),
                  subtitle: Text('Från ${ratingDetails.rater.name} för uppdraget "${ratingDetails.requestTitle}"'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text(ratingDetails.rating.ratingValue.toString()), const Icon(Icons.star, color: Colors.amber, size: 16)],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int count;
  const _StarRatingDisplay({required this.rating, required this.count});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (index) {
          return Icon(index < rating.round() ? Icons.star : Icons.star_border, color: Colors.amber);
        }),
        const SizedBox(width: 8),
        Text('$rating ($count omdömen)', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class StatusDisplay extends StatelessWidget {
  final String status;
  const StatusDisplay({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;
    switch (status) {
      case 'in_progress':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        label = 'Pågående';
        break;
      case 'completed':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        label = 'Slutförd';
        break;
      case 'archived':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        label = 'Arkiverad';
        break;
      default: // 'open'
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        label = 'Öppen';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}