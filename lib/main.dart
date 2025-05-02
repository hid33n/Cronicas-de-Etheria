// lib/main.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guild/services/noti_services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import 'firebase_options.dart';

// flutter_local_notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Services
import 'package:guild/viewmodels/auth/auth_service.dart';
import 'package:guild/viewmodels/auth/avatar_service.dart';
import 'package:guild/viewmodels/auth/user_repository.dart';
import 'services/audio_services.dart';

// ViewModels
import 'viewmodels/auth/auth_viewmodel.dart';
import 'viewmodels/guild/guild_viewmodel.dart';
import 'viewmodels/mission_viewmodel.dart';
import 'viewmodels/inventory_viewmodel.dart';
import 'viewmodels/blog_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/barracks_viewmodel.dart';
import 'viewmodels/army_viewmodel.dart';
import 'viewmodels/duel_viewmodel.dart';
import 'viewmodels/buildings/building_viewmodel.dart';
import 'viewmodels/battle_viewmodel.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/homescreen/home_screen.dart';
import 'screens/guild_list_screen.dart';
import 'screens/join_city_screen.dart';
import 'screens/missions_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/blog_screen.dart';
import 'screens/global_chat_message.dart';
import 'screens/city_chat_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/barracks/barracks_screen.dart';
import 'screens/army_screen.dart';
import 'screens/buildings_screen.dart';

/// Handler de background (anotado para AOT)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Mostrar notificación local en background
  const channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Canal para notificaciones importantes',
    importance: Importance.high,
  );
  final flnp = FlutterLocalNotificationsPlugin();
  await flnp
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final notification = message.notification;
  if (notification != null) {
    await flnp.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
  log('Background FCM message from ${message.from}: ${notification?.title}');
}

Future<void> _saveTokenToFirestore(String token) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
      log('FCM token saved for ${user.uid}');
    }
  } catch (e, st) {
    log('Error saving FCM token: $e\n$st');
  }
}

/// Instancia global para notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Canal de notificaciones Android por defecto
const AndroidNotificationChannel _notificationChannel =
    AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Canal para notificaciones importantes',
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance.init();



  // Persistencia offline en Firestore
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  // Registrar handler para background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar flutter_local_notifications
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_notificationChannel);
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (response) {
      log('Notification tapped: ${response.payload}');
    },
  );

  // Configurar FCM tokens
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await _saveTokenToFirestore(fcmToken);
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (newToken != null) _saveTokenToFirestore(newToken);
    });
  } catch (e, st) {
    log('FCM initialization error: $e\n$st');
  }
await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

  runApp(
    
    MultiProvider(
      providers: [
        // Servicios
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => UserRepository()),
        Provider(create: (_) => AvatarService()),
        Provider(create: (_) => AudioService()..playBackground()),

        // ViewModels
        ChangeNotifierProvider(
          create: (ctx) => AuthViewModel(
            authSvc: ctx.read<AuthService>(),
            userRepo: ctx.read<UserRepository>(),
            avatarSvc: ctx.read<AvatarService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => GuildViewmodel()),
        ChangeNotifierProvider(create: (_) => MissionViewModel()),
        ChangeNotifierProvider(create: (_) => InventoryViewModel()),
        ChangeNotifierProvider(create: (_) => BlogViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => BarracksViewModel()),
        ChangeNotifierProvider(create: (_) => ArmyViewModel()),
        ChangeNotifierProvider(create: (_) => DuelViewModel()),
        ChangeNotifierProvider(create: (_) => BuildingViewModel()),
        ChangeNotifierProvider(create: (_) => BattleViewModel()),
      ],
      child: const MusicApp(child: MyApp()),
    ),
  );
}

class MusicApp extends StatefulWidget {
  final Widget child;
  const MusicApp({required this.child, Key? key}) : super(key: key);

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> with WidgetsBindingObserver {
  late final AudioPlayer _player;
  bool _pausedByLifecycle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _player = AudioPlayer(playerId: 'background_music')
      ..setReleaseMode(ReleaseMode.loop)
      ..play(AssetSource('sounds/themesound.mp3'), volume: 0.3);

    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped && !_pausedByLifecycle && mounted) {
        _player.play(AssetSource('sounds/themesound.mp3'), volume: 0.3);
      }
    });

    // Notificaciones en foreground
    FirebaseMessaging.onMessage.listen((msg) {
      final notification = msg.notification;
      final android = msg.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _notificationChannel.id,
              _notificationChannel.name,
              channelDescription: _notificationChannel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
      log('FCM onMessage: ${notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      log('FCM onMessageOpenedApp: ${msg.data}');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pausedByLifecycle = false;
      _player.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedByLifecycle = true;
      _player.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crónicas de Etheria',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => SplashScreen(),
        '/login': (_) => LoginScreen(),
        '/main': (_) => MainNavScreen(initialIndex: 2),
        '/home': (_) => HomeScreen(),
        '/map': (_) => GuildListScreen(),
        '/join_city': (_) => JoinCityScreen(),
        '/missions': (_) => MissionsScreen(),
        '/inventory': (_) => InventoryScreen(),
        '/blog': (_) => BlogScreen(),
        '/chat_global': (_) => GlobalChatWidget(),
        '/chat_city': (_) => CityChatScreen(),
        '/profile': (_) => ProfileScreen(),
        '/barracks': (_) => BarracksScreen(),
        '/army': (_) => ArmyScreen(),
        '/buildings': (_) => BuildingsScreen(),
      },
    );
  }
}
