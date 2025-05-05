// lib/utils/errorcases.dart
// Definición de excepciones para centralizar todos los posibles errores del juego.

/// Error general del juego.
class GameException implements Exception {
  final String message;
  GameException([this.message = 'Ocurrió un error en el juego']);
  @override
  String toString() => message;
}

// -------- Entrenamiento --------

/// Recursos insuficientes para entrenar.
class InsufficientResourcesException extends GameException {
  InsufficientResourcesException([String message = 'Recursos insuficientes'])
      : super(message);
}

/// Máximo número de entrenamientos concurrentes alcanzado.
class MaxTrainingReachedException extends GameException {
  MaxTrainingReachedException([
    String message = 'Límite de entrenamientos alcanzado',
  ]) : super(message);
}

// -------- Mejora de edificio --------

/// Recursos insuficientes para mejorar el edificio.
class InsufficientUpgradeResourcesException extends GameException {
  InsufficientUpgradeResourcesException([
    String message = 'Recursos insuficientes para mejora',
  ]) : super(message);
}

/// Máximo número de mejoras concurrentes alcanzado.
class MaxUpgradeReachedException extends GameException {
  MaxUpgradeReachedException([
    String message = 'Límite de mejoras concurrentes alcanzado',
  ]) : super(message);
}

// -------- Gremio --------

/// Ya perteneces a un gremio.
class AlreadyInGuildException extends GameException {
  AlreadyInGuildException([
    String message = 'Ya formas parte de un gremio',
  ]) : super(message);
}

/// No perteneces a ningún gremio.
class NotInGuildException extends GameException {
  NotInGuildException([
    String message = 'No perteneces a ningún gremio',
  ]) : super(message);
}

/// El nombre de gremio ya está en uso.
class GuildNameTakenException extends GameException {
  GuildNameTakenException([
    String message = 'El nombre de gremio no está disponible',
  ]) : super(message);
}

/// No tienes permisos para realizar esta acción en el gremio.
class GuildPermissionException extends GameException {
  GuildPermissionException([
    String message = 'Permisos insuficientes en el gremio',
  ]) : super(message);
}

// -------- Usuario / Autenticación --------

/// Usuario no autenticado.
class NotAuthenticatedException extends GameException {
  NotAuthenticatedException([
    String message = 'Usuario no autenticado',
  ]) : super(message);
}

/// Error al conectar con la base de datos.
class DatabaseException extends GameException {
  DatabaseException([
    String message = 'Error de base de datos',
  ]) : super(message);
}

// -------- Otros --------

/// Error genérico de validación.
class ValidationException extends GameException {
  ValidationException([
    String message = 'Datos inválidos',
  ]) : super(message);
}

/// Acción no permitida.
class ActionNotAllowedException extends GameException {
  ActionNotAllowedException([
    String message = 'Acción no permitida',
  ]) : super(message);
}
