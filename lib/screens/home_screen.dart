import 'package:dndnb/models/update_banner.dart';
import 'package:dndnb/utils/platform_utils_stub.dart';
import 'package:dndnb/utils/pwa_utils.dart';
import 'package:dndnb/widgets/bottom_bar_widget.dart';
import 'package:dndnb/widgets/installPromptButton.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../main.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final AuthService _authService = AuthService();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("homeMessage");

  final _beerRef = FirebaseDatabase.instance.ref('beerStock/value');
  final FirebaseGameService _gameService = FirebaseGameService();

  bool isAdmin = false;
  String? userEmail;
  String? displayName;
  String? version;
  String? buildNumber;

  Future<String>? _homeMessageFuture;
  Future<String>? _releaseNoteFuture;

  @override
  void initState() {
    super.initState();

    _homeMessageFuture = _fetchHomeMessage();
    _releaseNoteFuture = _fetchReleaseNote();

    final user = _authService.currentUser;
    userEmail = user?.email;
    displayName = user?.displayName;
    if (user != null) {
      _authService.isUserAdmin(user.uid).then((value) {
        setState(() {
          isAdmin = value;
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _gameService.fetchUpcomingBeerContributions();
  }

  Future<String> _fetchHomeMessage() async {
    final messageRef = _dbRef;
    final snap = await messageRef.child('text').get();
    if (snap.exists) {
      return snap.value.toString().replaceAll("\\n", "\n");
    } else {
      return "Pas de message";
    }
  }

  Future<String> _fetchReleaseNote() async {
    final messageRef = _dbRef;
    final snap = await messageRef.child('releasenote').get();
    if (snap.exists) {
      return snap.value.toString().replaceAll("\\n", "\n");
    } else {
      return "Pas de message";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Accueil"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ecran de debug
            // if (isAdmin) const NotificationsDebug(),
            Text("Bienvenue, ${displayName ?? 'utilisateur'} !"),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/sessions');
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("Voir les sessions"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (isAdmin)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin');
                },
                icon: const Icon(Icons.shield),
                label: const Text("Espace Admin"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.person),
              label: const Text("Mettre à jour le profil"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    FutureBuilder<String>(
                      future: _homeMessageFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (!snapshot.hasData) {
                          return const Text("Aucun message pour le moment.");
                        }
                        return Text(
                          snapshot.data!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Icon(
                      Icons.new_releases,
                      size: 30,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<String>(
                      future: _releaseNoteFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (!snapshot.hasData) {
                          return const Text("");
                        }
                        return Text(
                          snapshot.data!,
                          textAlign: TextAlign.left,
                          style: theme.textTheme.bodyMedium,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (kIsWeb && !isIOSBrowser() && !isAppInstalled()) ...[
              const InstallPromptButton(),
            ],
            if (kIsWeb && isIOSBrowser()) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.ios_share, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Pour installer l'application :\nAppuyez sur "
                          "le bouton de partage (en bas de l'écran), "
                          "puis \"Ajouter à l’écran d’accueil\".",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            FutureBuilder(
              future: Future.wait([
                _beerRef.get(), // stock actuel
                _gameService
                    .fetchUpcomingBeerContributions(), // contributions prévues
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const CircularProgressIndicator();
                }

                final stockSnapshot = snapshot.data![0] as DataSnapshot;
                final stock = (stockSnapshot.value as num?)?.toDouble() ?? 0.0;
                final contributions = snapshot.data![1] as int;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        //const Icon(Icons.local_drink, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          "🍻 Réserve + Apports",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          // 🔴 Fond gris
                          Container(
                            height: 20,
                            width: double.infinity,
                            color: Colors.grey.shade800,
                          ),

                          // 🟩 Stock actuel (plein)
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (stock / 50).clamp(0.0, 1.0),
                            child: Container(height: 20, color: Colors.green),
                          ),

                          // 🟨 Apports à venir (translucide)
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: ((stock + contributions) / 50).clamp(
                              0.0,
                              1.0,
                            ),
                            child: Container(
                              height: 20,
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),

                          // 📊 Optionnel : texte au-dessus
                          Center(
                            child: Text(
                              "${(stock + contributions).clamp(0, 50).toInt()} bières",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      "Stock actuel : ${stock.toInt()}  |  Apports prévus : $contributions",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                );
              },
            ),

            const UpdateBanner(),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
