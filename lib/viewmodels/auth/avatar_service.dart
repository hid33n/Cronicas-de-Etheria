// lib/services/avatar_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AvatarService {
  final ImagePicker _picker = ImagePicker();

  /// Abre galería y devuelve el archivo seleccionado (o null).
  Future<File?> pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Sube el archivo al storage y devuelve la URL pública.
  Future<String> uploadAvatar(String uid, File file) async {
    final storageRef = FirebaseStorage.instance.ref('avatars/$uid.jpg');
    final uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await uploadTask.whenComplete(() {});
    return snapshot.ref.getDownloadURL();
  }
}
