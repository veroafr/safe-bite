# Cambios: login, registro e intolerancias dinámicas

## Login
- Campo de contraseña con "ojito" para mostrar u ocultar el texto (también en el registro, el cambio de contraseña y la recuperación).
- Validación de formato de email.
- **¿Olvidaste tu contraseña?** funciona en dos pasos:
  1. `POST /api/auth/recuperar-password` `{email}` genera un código de 6 dígitos (válido 15 min, máx. 5 intentos) y lo envía por email. La respuesta es la misma exista o no la cuenta.
  2. `POST /api/auth/restablecer-password` `{email, codigo, passwordNueva}`.
  - El código se guarda hasheado (BCrypt), nunca en claro.
  - **SMTP:** configurar las variables `SPRING_MAIL_HOST`, `SPRING_MAIL_PORT`, `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`, `SPRING_MAIL_PROPERTIES_MAIL_SMTP_AUTH=true`, `SPRING_MAIL_PROPERTIES_MAIL_SMTP_STARTTLS_ENABLE=true` (y opcional `MAIL_FROM`). Sin SMTP, el código se escribe en el log del servidor (útil en desarrollo).

## Crear usuario
- País y ciudad son **menús desplegables** encadenados (lista en `frontend/lib/core/data/ubicaciones.dart`; incluye "Otra ciudad").
- Email con formato obligatorio (`nombre@dominio.ext`).
- Contraseña: mínimo 6 caracteres, **1 mayúscula, 1 número y 1 carácter especial** (se valida en la app y en el backend; se muestran los requisitos con tildes).
- Sección **Restricción alimentaria**: chips con todas las intolerancias activas + opción **"Busco alimentarme mejor"**. Hay que elegir al menos una de las dos cosas.

## Intolerancias dinámicas
El enum fijo `GLUTEN / LACTOSA / FRUTOS_SECOS / MARISCOS` se reemplazó por la tabla `intolerancias`. Se siembran las 21 de la lista oficial (Anexo III), con los cereales **separados**:

Trigo, Centeno, Cebada, Avena, Crustáceos, Huevos, Pescados, Maní, Soja, Leche, Almendra, Avellanas, Castaña de cajú, Castaña de Pará, Macadamias, Nueces, Pecanas, Pistachos, Piñones, Castañas, Látex natural.

- `GET /api/intolerancias` (público): activas.
- Admin: `GET/POST /api/admin/intolerancias`, `PUT /{id}`, `PATCH /{id}/estado`, `DELETE /{id}` (solo las agregadas por el admin; las oficiales se desactivan).
- Cada intolerancia tiene **palabras clave** (es/pt/en) que usa el analizador de ingredientes del escáner; las nuevas que agrega el admin también se detectan. El analizador ahora compara palabras completas e ignora "sin gluten", "sem lactose", "gluten free", etc.
- En la app, el panel del admin tiene el módulo **Intolerancias** para agregar/editar/desactivar. Los cambios se ven en el registro, el perfil, los filtros y los formularios.

### Migración automática (al arrancar el backend)
`config/MigracionIntolerancias.java`:
- En PostgreSQL elimina las restricciones CHECK que Hibernate había creado para el enum viejo (si no, no se podrían guardar códigos nuevos).
- Traduce datos existentes: `GLUTEN` → Trigo, Centeno, Cebada, Avena · `LACTOSA` → Leche · `FRUTOS_SECOS` → Maní + todos los frutos secos · `MARISCOS` → Crustáceos.
- Recetas con etiqueta "Sin Gluten"/"Sin Lactosa"… pasan al campo nuevo `libreDe`.

## Perfil
- Aparecen todas las intolerancias activas para marcar/desmarcar, más el interruptor "Busco alimentarme mejor".
- Datos personales: país/ciudad con desplegables y validación de email.

## Filtros en cada sección (app de usuario y admin)
| Sección | Filtro |
|---|---|
| Restaurantes | locales aptos para **todas** las intolerancias elegidas |
| Recetas | recetas **libres de todas** las elegidas (campo `libreDe`) |
| Noticias | noticias relacionadas con **alguna** de las elegidas (campo `intolerancias`) |
| Escáner | contra qué intolerancias se evalúa el producto (por defecto las del perfil) |
| Admin › Productos (catálogo) | oculta productos que contienen alguna |

Todos los filtros tienen el atajo "Mis intolerancias". Los endpoints aceptan listas repetidas: `?intolerancias=TRIGO&intolerancias=LECHE`.

## Formularios del admin
Local, noticia, receta y producto muestran **todas** las intolerancias como chips (cada cereal por separado).
