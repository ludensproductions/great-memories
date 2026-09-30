# Entorno de desarrollo local (Windows)

Cómo dejar Great Memories corriendo en tu PC para desarrollar: el servidor en Docker Desktop y la app móvil con Flutter en un celular Android.

Para instalar un servidor "de verdad" (Raspberry Pi / Ubuntu Server) ver [CONFIGURACION-SERVIDOR.md](CONFIGURACION-SERVIDOR.md).

---

## Cómo queda armado

| Pieza | Dónde corre | De dónde sale |
|---|---|---|
| Servidor + web (`great_memories_server`, puerto 2283) | Docker Desktop | Imagen `ghcr.io/ludensproductions/great-memories-server:main` |
| Machine learning (`great_memories_machine_learning`) | Docker Desktop | Imagen `ghcr.io/ludensproductions/great-memories-machine-learning:main` |
| Postgres (`great_memories_postgres`) y Redis (`great_memories_redis`) | Docker Desktop | Imágenes públicas |
| App móvil | Celular Android (o emulador) vía `flutter run` | Código de `mobile/` |

El servidor **no se compila localmente**: se usan las imágenes que CI publica en cada push a `main` ([.github/workflows/docker.yml](.github/workflows/docker.yml)). Si cambias código de `server/` o `web/`, el cambio llega a tu Docker hasta que se mergea a `main`, termina CI y haces `docker compose pull` (ver [Actualizar el servidor](#actualizar-el-servidor)). Para iterar sobre server/web sin pasar por CI, ver [Stack completo en modo dev](#opcional-stack-completo-en-modo-dev).

---

## 1. Instalar herramientas

| Herramienta | Versión | Notas |
|-------------|---------|-------|
| Windows 10/11 + WSL2 | — | `wsl --install` en PowerShell como administrador, luego reiniciar. |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Reciente | Backend **WSL2** (Settings → General → "Use the WSL 2 based engine"). Asignarle ≥ 6 GB de RAM si usas Hyper-V. |
| [Git](https://git-scm.com/download/win) | Reciente | |
| [Flutter](https://docs.flutter.dev/get-started/install/windows/mobile) | **3.44.x** (`>=3.44.6 <3.45.0`, ver [mobile/pubspec.yaml](mobile/pubspec.yaml)) | Agregar `flutter\bin` al `PATH`. Otra versión menor falla en `pub get`. |
| [Android Studio](https://developer.android.com/studio) | Reciente | Instala Android SDK, platform-tools (`adb`) y emulador. Después: `flutter doctor --android-licenses`. |
| JDK | 21 | El que trae Android Studio sirve. |
| VS Code + extensiones Flutter/Dart | Opcional | |

Verificar:

```powershell
docker version
flutter --version
flutter doctor
```

`flutter doctor` debe salir sin errores en **Flutter** y **Android toolchain** (lo de Visual Studio / Chrome se puede ignorar).

---

## 2. Clonar el repo

```powershell
git clone https://github.com/ludensproductions/great-memories.git
cd great-memories
```

---

## 3. Configurar `docker/.env`

```powershell
cd docker
copy example.env .env
notepad .env
```

Cambiar estos valores (el resto se queda igual):

```ini
UPLOAD_LOCATION="C:/Users/<tu-usuario>/Pictures/Fotos Great Memories"
DB_DATA_LOCATION="C:/Users/<tu-usuario>/Documents/DB Great Memories"
GREAT_MEMORIES_VERSION=main
DB_PASSWORD=<aleatorio, solo A-Za-z0-9>
# TZ=America/Mexico_City
```

- `GREAT_MEMORIES_VERSION=main` es **obligatorio**: `example.env` trae `v3`, pero esa etiqueta todavía no existe en GHCR y el pull falla con `manifest unknown`.
- Rutas entre comillas si tienen espacios. Las carpetas se crean solas.
- Contraseña aleatoria en PowerShell: `-join ((48..57)+(65..90)+(97..122) | Get-Random -Count 24 | % {[char]$_})`
- `.env` está en `.gitignore`: nunca se sube.

---

## 4. Levantar el servidor

Con Docker Desktop abierto, desde `docker/`:

```powershell
docker compose up -d
```

La primera vez descarga varios GB. Verificar:

```powershell
docker compose ps                                  # 4 contenedores "running"/"healthy"
curl.exe http://localhost:2283/api/server/ping     # {"res":"pong"}
```

Abrir <http://localhost:2283> y registrar el primer usuario: **queda como administrador**.

Los contenedores tienen `restart: always`: arrancan solos cada vez que abre Docker Desktop.

---

## 5. Permitir que el celular llegue a la PC

El celular se conecta a la IP de tu PC en la red local, así que Windows Firewall debe dejar pasar el puerto 2283. En **PowerShell como administrador**, una sola vez:

```powershell
New-NetFirewallRule -DisplayName "Great Memories 2283" -Direction Inbound -Protocol TCP -LocalPort 2283 -RemoteAddress LocalSubnet -Action Allow
```

Tu IP local: `ipconfig` → "Dirección IPv4" del adaptador Wi-Fi/Ethernet (p. ej. `192.168.1.50`). Probar desde el navegador del celular: `http://192.168.1.50:2283`.

> El descubrimiento automático (mDNS/BLE) **no** funciona en este entorno: eso lo publica `deploy.sh` en el servidor Linux. En la app, capturar la URL del servidor a mano.

---

## 6. App móvil

Desde `mobile/`:

```powershell
cd mobile
flutter pub get

# Generar traducciones (lib/generated/ no está versionado; sin esto no compila)
dart run easy_localization:generate -S ../i18n
dart run bin/generate_keys.dart
```

Conectar el celular por USB con **depuración USB** activada (Opciones de desarrollador) y aceptar la huella en el celular. Luego:

```powershell
flutter devices    # debe aparecer tu celular
flutter run
```

- La versión debug se instala como `com.greatmemories.app.debug`, así que convive con la app de producción.
- En la pantalla de login, servidor: `http://<IP-de-tu-PC>:2283`.
- Durante `flutter run`: `r` = hot reload, `R` = hot restart, `q` = salir.
- Para generar un APK instalable (release): ver [GENERAR-APK.md](GENERAR-APK.md).

Volver a correr los dos comandos de traducciones cada vez que cambie algo en `i18n/`. El código generado de rutas (`router.gr.dart`) y del cliente OpenAPI (`mobile/openapi/`) ya está versionado; solo se regenera si cambias rutas o la API (`dart run build_runner build --delete-conflicting-outputs`).

---

## Comandos del día a día

Desde `docker/`:

| Qué | Comando |
|---|---|
| Levantar | `docker compose up -d` |
| Detener (conserva datos) | `docker compose down` |
| Estado | `docker compose ps` |
| Logs del servidor | `docker compose logs -f great-memories-server` |
| Logs de ML | `docker compose logs -f great-memories-machine-learning` |
| Reiniciar solo el servidor | `docker compose restart great-memories-server` |

## Actualizar el servidor

Después de que un cambio se mergea a `main` y termina el workflow de Docker en GitHub Actions:

```powershell
cd docker
docker compose pull
docker compose up -d
```

## Borrar todo y empezar de cero

```powershell
cd docker
docker compose down -v
```

Luego borrar a mano las carpetas de `UPLOAD_LOCATION` y `DB_DATA_LOCATION`. ⚠️ Se pierden todas las fotos y usuarios.

---

## (Opcional) Stack completo en modo dev

Para cambiar código de `server/` o `web/` con hot reload, sin esperar a CI. Usa [docker/docker-compose.dev.yml](docker/docker-compose.dev.yml) vía [mise](https://mise.jdx.dev/), que instala las versiones exactas de Node (24.x) y pnpm que pide [mise.toml](mise.toml).

```powershell
docker compose -f docker/docker-compose.yml down   # libera el puerto 2283
winget install jdx.mise
mise trust
mise install
mise dev          # detener con Ctrl+C (corre mise dev-down al salir)
```

Web en <http://localhost:3000>, API en <http://localhost:2283>. Detalles en [docs/docs/developer/setup.md](docs/docs/developer/setup.md). En Windows este modo es más lento que en Linux/macOS porque el código se monta desde NTFS hacia WSL2; clonar el repo dentro de WSL (`\\wsl$\Ubuntu\home\...`) lo acelera bastante.

---

## Problemas comunes

| Síntoma | Solución |
|---|---|
| `manifest unknown` / `not found` en el pull | `GREAT_MEMORIES_VERSION=main` en `docker/.env` |
| `error during connect` / `docker: command not found` | Docker Desktop no está abierto |
| `ping` no responde justo después de `up -d` | Esperar 1–2 min; revisar `docker compose logs -f great-memories-server` |
| El celular no conecta al servidor | Misma red Wi-Fi que la PC; regla de firewall del paso 5; usar la IP, no `localhost` |
| Red Wi-Fi marcada como "Pública" y sigue sin conectar | Configuración → Red → cambiar a "Privada", o revisar la regla de firewall |
| `flutter pub get` falla por versión del SDK | Usar Flutter 3.44.x (`flutter --version`) |
| Error de compilación por `lib/generated/...` faltante | Correr los dos comandos de traducciones del paso 6 |
| `flutter devices` no muestra el celular | Revisar cable/depuración USB, aceptar la huella; `adb devices` |
| `pnpm` falla con `No such built-in module: node:sqlite` | Node global demasiado viejo (< 22). Usar `mise install` o actualizar Node a 24 |
| `great_memories_machine_learning` reinicia en bucle | Poca RAM para Docker/WSL2; subirla en Docker Desktop o en `%UserProfile%\.wslconfig` |
