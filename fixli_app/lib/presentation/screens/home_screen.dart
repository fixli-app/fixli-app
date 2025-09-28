// lib/presentation/screens/home_screen.dart

import 'dart:async'; // Ny import för Timer
import 'dart:math'; // Ny import för Random
import 'package:fixli_app/data/repositories/request_repository.dart';
import 'package:fixli_app/presentation/providers/auth_provider.dart';
import 'package:fixli_app/presentation/providers/notification_provider.dart';
import 'package:fixli_app/presentation/providers/request_provider.dart';
import 'package:fixli_app/presentation/screens/ads_screen.dart';
import 'package:fixli_app/presentation/screens/create_request_screen.dart';
import 'package:fixli_app/presentation/screens/faq_screen.dart';
import 'package:fixli_app/presentation/screens/notifications_screen.dart';
import 'package:fixli_app/presentation/screens/profile_screen.dart';
import 'package:fixli_app/presentation/screens/tasks_screen.dart';
import 'package:fixli_app/presentation/widgets/detail_dialogs.dart';
import 'package:fixli_app/presentation/widgets/empty_state_widget.dart';
import 'package:fixli_app/presentation/widgets/shimmer_list_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🟢 NYA IMPORTER FÖR NYHETSSKÄRMAR
import 'package:fixli_app/presentation/screens/news_screen.dart';
import 'package:fixli_app/presentation/screens/admin_news_screen.dart';


// Ändrad till ConsumerStatefulWidget för att hantera Timer och PageController
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
// PageController initialiseras med ett startindex mitt i det stora "oändliga" intervallet
  late PageController _pageController;
  Timer? _timer;
// _currentPage kommer nu att spåra det stora indexet, inte det faktiska bildindexet
  int _currentPage = 0;

// Bannerdata
  List<Map<String, String>> bannerData = [ // Gjort till icke-final så vi kan blanda den
    {
      'title': 'Har du ett projekt på gång?',
      'subtitle': 'Lägg upp ett uppdrag på några minuter och få hjälp av duktiga Fixare i ditt område.',
      'image': 'assets/Project.png',
    },
    {
      'title': 'Få det fixat, helt enkelt.',
      'subtitle': 'Lägg ut din att-göra-lista och låt någon annan ta hand om jobbet.',
      'image': 'assets/Checklist.png',
    },
    {
      'title': 'Från montering till trädgårdsarbete.',
      'subtitle': 'Oavsett vad du behöver hjälp med, finns det en Fixare för just ditt uppdrag.',
      'image': 'assets/Gardening.png',
    },
    {
      'title': 'Anlita med förtroende.',
      'subtitle': 'Se betyg och tidigare omdömen för att hitta den perfekta Fixaren för dig.',
      'image': 'assets/Review.png',
    },
    {
      'title': 'Vad behöver du hjälp med idag?',
      'subtitle': 'Tryck på plus-knappen och beskriv ditt uppdrag. Hjälpen är närmare än du tror.',
      'image': 'assets/Help.png',
    },
    {
      'title': 'Tjäna extra pengar på din talang.',
      'subtitle': 'Hitta uppdrag nära dig och få betalt för det du är bra på.',
      'image': 'assets/Money.png',
    },
    {
      'title': 'Dina kunskaper är efterfrågade.',
      'subtitle': 'Oavsett om du är expert eller bara händig, finns det någon som behöver just din hjälp.',
      'image': 'assets/Skills.png',
    },
    {
      'title': 'Jobba när det passar dig.',
      'subtitle': 'Sök bland hundratals lokala uppdrag och välj de som passar ditt schema.',
      'image': 'assets/Schedule.png',
    },
    {
      'title': 'Bli en lokal hjälte.',
      'subtitle': 'Hjälp en granne och tjäna en slant på samma gång.',
      'image': 'assets/Hero.png',
    },
    {
      'title': 'Din lokala hjälp, ett klick bort.',
      'subtitle': 'Fixli kopplar ihop grannar som behöver hjälp med de som kan hjälpa till.',
      'image': 'assets/Neighbours.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _shuffleBannerData(); // Blanda ordningen vid start
// Initialisera PageController med ett startindex mitt i det stora intervallet
// Detta förhindrar att karusellen "hoppar" i början eller slutet.
    _currentPage = (10000 ~/ 2) - ((10000 ~/ 2) % bannerData.length);
    _pageController = PageController(initialPage: _currentPage);
    _startAutoScroll();
  }

  void _shuffleBannerData() {
    final random = Random();
    bannerData.shuffle(random);
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 300), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage++; // Öka bara index, kommer att loopa "oändligt"
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final latestRequestsAsync = ref.watch(latestRequestsProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🟢 HÄR ÄR ÄNDRINGEN FÖR ADMIN-KONTROLLEN
    // Använder user.name för att bestämma om användaren är admin
    final isAdmin = (user.name.toLowerCase() == 'admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixli'),
        actions: [
          const _NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logga ut',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.name),
              accountEmail: Text(user.email),
              decoration: const BoxDecoration(color: Colors.teal),
            ),
            ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Alla uppdrag'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()));
                }),
            ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: const Text('Utvalda företag'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdsScreen()));
                }),
            ListTile(
                leading: const Icon(Icons.article_outlined), // 🟢 ICON FÖR NYHETER
                title: const Text('Nyheter'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen())); // 🟢 NAVIGERA TILL NYHETSSKÄRMEN
                }),
            ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Min profil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                }),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Vanliga frågor (FAQ)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()));
                }),
            // 🟢 HÄR KONTROLLERAS ADMIN-STATUS
            if (isAdmin) ...[ // Visa endast om användaren är admin (namn "admin")
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_note_outlined), // 🟢 ICON FÖR ADMIN NYHETER
                title: const Text('Hantera nyheter'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNewsScreen())); // 🟢 NAVIGERA TILL ADMIN NYHETSSKÄRMEN
                },
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen()));
        },
        tooltip: 'Skapa nytt uppdrag',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(latestRequestsProvider);
          ref.invalidate(requestListProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Välkommen, ${user.name}!', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Här i Fixli kan du enkelt hitta hjälp med vardagssysslor eller erbjuda dina egna tjänster till andra i ditt område. Skapa ett uppdrag med plusknappen eller utforska de senaste uppdragen nedan.',
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),

// Här är bannern med PageView
                    SizedBox(
                      height: MediaQuery.of(context).size.width / (16 / 9), // 16:9 proportioner
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: 10000,
// Inaktivera scroll
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
// Använd modulo för att få det faktiska bildindexet
                          final actualIndex = index % bannerData.length;
                          final item = bannerData[actualIndex];
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: AssetImage(item['image']!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.3), // Mörkare för bättre läsbarhet
                                  BlendMode.darken,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']!,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['subtitle']!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24), // Lite luft efter bannern

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Senaste uppdragen', style: Theme.of(context).textTheme.titleLarge),
                        TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()));
                            },
                            child: const Text('Visa alla')),
                      ],
                    ),
                    const Divider(), // Den befintliga linjen
                  ],
                ),
              ),
            ),
            latestRequestsAsync.when(
              loading: () => const SliverToBoxAdapter(child: ShimmerListPlaceholder(itemCount: 3)),
              error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Fel: $err'))),
              data: (requests) {
                if (requests.isEmpty) {
                  return const SliverToBoxAdapter(child: EmptyStateWidget(title: 'Inga uppdrag just nu', subtitle: 'Var den första att skapa ett uppdrag via plus-knappen!'));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final requestWithUser = requests[index];
                      final request = requestWithUser.request;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(request.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${request.location} • ${request.price} kr'),
                          trailing: StatusDisplay(status: request.status),
                          onTap: () => showRequestDetailDialog(context, requestWithUser, ref),
                        ),
                      );
                    },
                    childCount: requests.length,
                  ),
                );
              },
            ),
// 🟢 Ny sektion för den extra linjen, copyright och flagga
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0), // Luft ovanför och under
                child: Column(
                  children: [
                    const Divider(), // Den nya linjen i botten
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '© 2025 Fixli. Alla rättigheter förbehållna.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/Sweden.png', // Sökväg till din svenska flagga
                          width: 20, // Justera storleken vid behov
                          height: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
// Denna padding kan justeras eller tas bort om den nya sektionen ger tillräckligt med utrymme.
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 30.0), // Justera värdet vid behov
            ),
          ],
        ),
      ),
    );
  }
}


// Ny widget för klock-ikonen med notis-räknare
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider).asData?.value ?? 0;

    return IconButton(
      icon: Badge(
        label: Text(unreadCount.toString()),
        isLabelVisible: unreadCount > 0,
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      },
      tooltip: 'Aviseringar',
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