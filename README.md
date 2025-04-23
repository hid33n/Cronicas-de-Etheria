# Crónicas de Etheria 🏰

¡Bienvenido a **Crónicas de Etheria**, un RPG medieval ambientado en un mundo de fantasía e intriga! Aquí podrás entrenar tus tropas, gestionar recursos y lanzarte al **PvP** contra oponentes reales, todo en tiempo real gracias a **Firebase Firestore**.

---

## 🔥 Características Principales

- 🏰 **Cuartel (Barracks)**
  - Visualiza tu ejército actual con información de 🗡️ **ATK**, 🛡️ **DEF** y ❤️ **HP**.
  - Entrena nuevas unidades ajustando la **cantidad**, comprobando **costos** (madera, piedra, comida) y **tiempo de entrenamiento** en vivo.
  - Soporta **unidades genéricas** y **exclusivas por raza** (🔱 badge para unidades únicas).

- ⚔️ **Duelo PvP**
  - Selecciona tropas entrenadas desde tu campo `army` en Firestore.
  - Visualiza imagen, stats y cantidad disponible de cada unidad.
  - Lanza un combate aleatorio contra otro jugador y recibe un **informe** con pérdidas, sobrevivientes y recompensas.
  - Los reportes se guardan en `users/{uid}/pvp_reports` para consultar historial.

- 💬 **Chat Global**
  - Widget de chat integrado para comunicarte con toda la comunidad.
  - Scroll automático y controles de visibilidad para no entorpecer la UI.

- 🔄 **Sincronización en Tiempo Real**
  - Firebase Firestore como backend para: recursos, cola de entrenamiento (`barracksQueue`), ejército y reportes.
  - Listeners para actualizaciones instantáneas sin recargar la app.

- 🌐 **Gestión de Raza**
  - Cada jugador tiene una **raza** (`user.race`), que determina qué unidades exclusivas puede entrenar.
  - Filtros automáticos en `BarracksScreen` y `PvPDialog` para mostrar solo las unidades disponibles.

- 🎨 **Estética “Medieval Minimalista”**
  - Tema oscuro con acentos **ambar** y **grises**.
  - Emoticonos y badges para reforzar la ambientación RPG.

---

## 🚀 Tecnología y Arquitectura

- **Flutter & Dart**: UI nativa en Android, iOS y Web.
- **Provider**: Gestión de estado simple y eficiente.
- **Firebase Firestore**: Base de datos NoSQL en tiempo real.
- **Cloud Functions (opcional)**: Lógica de batalla y reportes.

---

## 🛠️ Instalación

1. Clona el repositorio:
   ```bash
   git clone https://github.com/tu-usuario/cronicas-de-etheria.git
   cd cronicas-de-etheria
   ```
2. Instala dependencias:
   ```bash
   flutter pub get
   ```
3. Configura Firebase:
   - Añade tu `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) en `android/app` y `ios/Runner`.
   - Habilita Firestore en tu proyecto de Firebase.
4. Ejecuta la app:
   ```bash
   flutter run
   ```

---

## 📋 Roadmap

- [ ] Sistema de **Contribución de Gremios**
- [ ] **Leaderboard** global de PvP
- [ ] **Notificaciones** push para eventos de batalla
- [ ] **Localización** (i18n) para múltiples idiomas

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Abre un **Issue** o envía un **Pull Request** con nuevas unidades, mejoras de UI o corrección de errores.

---

© 2025 Crónicas de Etheria. Creado con ❤️ por la comunidad Guild.

