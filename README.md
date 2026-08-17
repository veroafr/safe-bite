# Safe-Bite

Aplicación de gestión de restaurantes, recetas, noticias y productos aptos para personas con intolerancias alimentarias (gluten, lactosa, frutos secos, mariscos), generada a partir de los diagramas de casos de uso y wireframes provistos.

- **Backend**: Java 17 + Spring Boot 3 + Spring Security (JWT) + PostgreSQL + JPA
- **Frontend**: Flutter (Android / iOS / Web) + Provider

```
safebite/
├── backend/     API REST Spring Boot
├── frontend/    App Flutter
└── docker-compose.yml   Levanta Postgres + backend juntos
```

## 1. Backend (Spring Boot)

### Requisitos
- Java 17+
- Maven 3.9+
- PostgreSQL 14+ (o Docker)

### Levantar con Docker (recomendado)

```bash
cd safebite
docker compose up --build
```

Esto levanta Postgres en `localhost:5432` y el backend en `http://localhost:8080`.

### Levantar manualmente

```bash
cd safebite/backend
# Postgres local: crear DB "safebite", usuario/clave "safebite" (o exportar DB_HOST/DB_USER/DB_PASSWORD)
mvn spring-boot:run
```

Para usar H2 en memoria en vez de Postgres (rapido, sin instalar nada):

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=h2
```

### Datos de prueba (se cargan automáticamente al iniciar si la base está vacía)

| Rol | Email | Contraseña |
|---|---|---|
| Administrador | admin@safebite.com | admin123 |
| Usuario | maria@email.com | usuario123 |

### Documentación interactiva (Swagger)

`http://localhost:8080/swagger-ui.html`

### Endpoints principales

- `POST /api/auth/registro` / `POST /api/auth/login` / `POST /api/auth/recuperar-password`
- `GET/PUT /api/usuarios/me`, `PUT /api/usuarios/me/password`, `PUT /api/usuarios/me/preferencias`
- `GET /api/restaurantes`, `GET /api/restaurantes/{id}`, comentarios y evaluaciones anidados
- `GET /api/recetas` (filtro `esTip`, `usarMisIntolerancias`)
- `GET /api/noticias`
- `GET /api/productos/buscar`, `GET /api/productos/ean/{codigo}`, `POST /api/productos/ocr`
- `POST /api/alertas`, `GET /api/alertas/me`
- `/api/admin/**` (requiere rol ADMINISTRADOR): CRUD de restaurantes, recetas, noticias, productos, usuarios; revisión de alertas; `/api/admin/reportes/estadisticas` y `/api/admin/reportes/exportar-pdf`

## 2. Frontend (Flutter)

El código fuente (`lib/`, `pubspec.yaml`) ya está escrito, pero **las carpetas nativas `android/` e `ios/` deben generarse en tu máquina** (no se pueden generar sin el SDK de Flutter instalado):

```bash
cd safebite/frontend
flutter create --org com.safebite --project-name safebite_app .
flutter pub get
```

El comando anterior completa `android/`, `ios/`, `web/`, etc. sin tocar el `lib/` ni el `pubspec.yaml` que ya están armados.

### Permisos a agregar manualmente

**Android** (`android/app/src/main/AndroidManifest.xml`), dentro de `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
```
Y `minSdkVersion 21` (o superior) en `android/app/build.gradle` — lo requieren `mobile_scanner` y `google_mlkit_text_recognition`.

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Safe-Bite necesita la cámara para escanear productos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Safe-Bite necesita acceder a tus fotos para el escáner</string>
```

### Configurar la URL del backend

Por defecto la app usa `http://10.0.2.2:8080/api` en el emulador Android y `http://localhost:8080/api` en iOS/web/desktop (ver `lib/core/api/api_config.dart`). Para apuntar a otra URL (ej. backend en la nube o dispositivo físico):

```bash
flutter run --dart-define=SAFEBITE_API_URL=http://TU_IP:8080/api
```

### Correr la app

```bash
cd safebite/frontend
flutter run
```

## 3. Estructura funcional (según los casos de uso)

**Usuario**: Pantalla principal (elegir idioma, login, registro, recuperar contraseña) → Dashboard con 5 módulos: Restaurantes (buscador, filtros, mapa, comentarios, evaluaciones, alertas), Recetas y Tips (filtro por intolerancias), Escáner de Productos (lector EAN/UPC, lector OCR, buscador manual), Noticias, Perfil (datos personales, intolerancias, nivel de alerta, tipos de cocina, seguridad).

**Administrador**: Login → Dashboard con gestión CRUD de Restaurantes, Alertas (revisar/aceptar/denegar), Noticias, Recetas, Usuarios, y Reportes y Estadísticas (con exportación a PDF).

## 4. Notas de implementación

- El lector EAN/UPC y el buscador manual consultan el catálogo de productos cargado por el administrador. El lector OCR usa reconocimiento de texto en el dispositivo (`google_mlkit_text_recognition`) y busca coincidencias por nombre en el backend — en producción conviene sumar un proveedor externo de datos nutricionales (ej. OpenFoodFacts) para ampliar el catálogo.
- La geolocalización del mapa usa `flutter_map` + OpenStreetMap (sin API key). El filtro "por ubicación" del wireframe puede ampliarse a búsqueda por radio agregando cálculo de distancia en `RestauranteService` (backend).
- Este entorno de generación no tiene Flutter/Maven instalados, por lo que el código no pudo compilarse automáticamente acá. Se revisó manualmente sintaxis, imports y balance de llaves/paréntesis en los 43 archivos Dart y 78 archivos Java. Corré `mvn compile` y `flutter analyze` como primer paso al abrir el proyecto.
# safe-bite
