import 'package:flutter/material.dart';
import 'package:guild/models/user_model.dart';
import 'package:guild/viewmodels/auth/auth_service.dart';
import 'package:guild/viewmodels/auth/avatar_service.dart';
import 'package:guild/viewmodels/auth/presence_service.dart';
import 'package:guild/viewmodels/auth/user_repository.dart';


class AuthViewModel extends ChangeNotifier {
  final AuthService _authSvc;
  final UserRepository _userRepo;
  final AvatarService _avatarSvc;
  late final PresenceService _presence;

  UserModel? _user;
  UserModel? get user => _user;

  AuthViewModel({
    required AuthService authSvc,
    required UserRepository userRepo,
    required AvatarService avatarSvc,
  })  : _authSvc = authSvc,
        _userRepo = userRepo,
        _avatarSvc = avatarSvc {
    // Escuchar cambios de autenticación
    _authSvc.authChanges().listen((fbUser) {
  if (fbUser != null) {
    _loadCurrentUser(fbUser.uid).then((_) {
      // Inicializamos la presencia:
// dentro de AuthViewModel, tras cargar el usuario:
_presence = PresenceService(fbUser.uid);
// suponiendo que _user es tu UserModel cargado
_presence.goOnline(_user!.name);
    });
  } else {
    // Al desconectarse de FirebaseAuth:
    _presence.goOffline(_user!.name);
    _user = null;
    notifyListeners();
  }
});
 }

  Future<void> _loadCurrentUser(String uid) async {
    _user = await _userRepo.loadUser(uid);
    notifyListeners();
  }

  Future<void> signIn(String identifier, String password) async {
    String email = identifier.contains('@')
        ? identifier.trim()
        : (await _userRepo.getEmailByUsername(identifier))!;
    final cred = await _authSvc.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _loadCurrentUser(cred.user!.uid);
  }

  Future<void> signUp(
      String name, String email, String password, String raceId) async {
    // Validar nombre
    final existingEmail = await _userRepo.getEmailByUsername(name);
    if (existingEmail != null) {
      throw Exception('El nombre de aventurero "$name" ya está en uso.');
    }

    final cred = await _authSvc.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    // Crear documento con datos iniciales
    await _userRepo.updateFields(uid, {
      'name': name,
      'email': email.trim(),
      'cityId': null,
      'gold': 0,
      'race': raceId,
      'avatarUrl': '',
      'missionsCompleted': 0,
      'achievements': <String>[],
      'eloRating': 1000,
    });

    // Luego _loadCurrentUser creará los edificios y recursos si hace falta
    await _loadCurrentUser(uid);
  }

  Future<void> signOut() async {
    await _authSvc.signOut();
  }

  Future<void> uploadAvatar() async {
    final fbUser = _authSvc.currentUser;
    if (fbUser == null) throw Exception('No hay usuario conectado.');

    final file = await _avatarSvc.pickImage();
    if (file == null) return;

    final url = await _avatarSvc.uploadAvatar(fbUser.uid, file);
    await _userRepo.updateFields(fbUser.uid, {'avatarUrl': url});
    _user?.avatarUrl = url;
    notifyListeners();
  }

  Future<void> updateAvatarUrl(String url) =>
      _userRepo.updateFields(_user!.id, {'avatarUrl': url});

  Future<void> incrementMissionsCompleted() =>
      _userRepo.updateFields(_user!.id, {
        'missionsCompleted': (_user?.missionsCompleted ?? 0) + 1,
      });
Future<void> loadCurrentUser() async {
  final uid = _authSvc.currentUser?.uid;
  if (uid != null) {
    await _loadCurrentUser(uid);
  }
}
  Future<void> addAchievement(String trophy) =>
      _userRepo.updateFields(_user!.id, {
        'achievements': [...?_user?.achievements, trophy],
      });

  Future<void> setCityId(String? cityId) =>
      _userRepo.updateFields(_user!.id, {'cityId': cityId});

  Future<void> updateGold(int newGold) =>
      _userRepo.updateFields(_user!.id, {'gold': newGold});

  Future<void> updateEloRating(int newRating) =>
      _userRepo.updateFields(_user!.id, {'eloRating': newRating});
}
