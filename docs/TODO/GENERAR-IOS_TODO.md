# App de iOS (iPhone): estado actual y pasos para generarla

Qué hay hoy en el repo para iOS, qué falta y la lista de pasos para tener la app instalable en iPhone.

Equivalente Android: [GENERAR-APK.md](GENERAR-APK.md).

---

## Antes de empezar: en iOS no hay "APK"

El equivalente del APK es el **IPA**, pero en iPhone no se puede pasar el archivo por WhatsApp e instalarlo como en Android. Apple solo deja instalar apps por estas vías:

| Vía | Qué se necesita | Para qué sirve | Límites |
|---|---|---|---|
| **Xcode directo al iPhone** (cable) | Mac + Apple ID gratuito | Desarrollo y pruebas propias | La app caduca a los **7 días**, máx. 3 apps; algunas capacidades (Associated Domains, etc.) no funcionan con cuenta gratuita |
| **Ad Hoc** (archivo `.ipa`) | Mac + Apple Developer Program (99 USD/año) | Lo más parecido a "pasar un APK": se instala en iPhones registrados | Hay que registrar el UDID de cada iPhone (máx. 100 por tipo de equipo al año) |
| **TestFlight** | Mac + Apple Developer Program | Beta para el equipo y testers | Hasta 10 000 testers; cada build dura 90 días; los testers externos requieren una revisión ligera de Apple |
| **App Store** | Mac + Apple Developer Program + ficha aprobada | Usuarios finales | Revisión de Apple en cada versión |

**Sin una Mac no se puede compilar para iOS.** Las PCs con Windows del equipo no sirven para esto. Opciones: Mac física, Mac en la nube (MacinCloud, AWS EC2 Mac) o dejar que lo compile CI en GitHub (runners `macos`, ver Fase 6).

---

## Lo que ya se tiene

| Qué | Dónde | Estado |
|---|---|---|
| Proyecto iOS completo (app + extensión para compartir + widget) | [mobile/ios/](mobile/ios/) | ✅ Heredado de Immich; es la misma app Flutter, no hay que escribir otra |
| Bundle IDs con la marca | [mobile/ios/Signing.xcconfig](mobile/ios/Signing.xcconfig) | ✅ `com.greatmemories.app` (prod), `com.greatmemories.app.dev` (debug), grupo `group.com.greatmemories.app.share` |
| Firma configurable por desarrollador | `Signing.xcconfig` incluye `Signing.local.xcconfig` (en `.gitignore`) | ✅ Cada quien puede usar su Team ID sin tocar el repo |
| Firma automática en Xcode | `Runner.xcodeproj` (`CODE_SIGN_STYLE = Automatic`, `DEVELOPMENT_TEAM = $(GREAT_MEMORIES_TEAM_ID)`) | ✅ Xcode crea los perfiles solo |
| Permisos de Bluetooth y red local | [mobile/ios/Runner/Info.plist](mobile/ios/Runner/Info.plist) | ✅ `NSBluetoothAlwaysUsageDescription`, `NSLocalNetworkUsageDescription`, `NSBonjourServices` con `_great_memories._tcp` |
| Descubrimiento del servidor contempla iOS | [mobile/lib/services/server_discovery.service.dart](mobile/lib/services/server_discovery.service.dart) | ✅ Maneja el permiso de Bluetooth de iOS (línea 241) |
| Versión mínima | `Podfile` / Xcode | iOS 15 (widget: 16–17) |
| Lanes de Fastlane (TestFlight dev y release prod) | [mobile/ios/fastlane/Fastfile](mobile/ios/fastlane/Fastfile) | ⚠️ Existen, pero con identidad de Immich (ver abajo) |
| Job de CI que compila, firma y sube a TestFlight | `build-sign-ios` en [.github/workflows/build-mobile.yml](.github/workflows/build-mobile.yml) | ⚠️ Existe, pero no puede correr para nosotros (ver abajo) |

## Lo que falta (bloqueos)

| # | Bloqueo | Dónde | Ref. |
|---|---|---|---|
| 1 | No hay Mac ni cuenta de **Apple Developer Program** propia | — | [REBRANDING_TODO #11](REBRANDING_TODO.md) |
| 2 | Team ID `2W7AC6T8T5` es el de Immich (FUTO Holdings) | `Signing.xcconfig`, `Fastfile` (`TEAM_ID`, `CODE_SIGN_IDENTITY = "Apple Distribution: FUTO Holdings, Inc."`) | #12 |
| 3 | Apple ID de Fastlane es del fundador de Immich (`altran@futo.org`) | [mobile/ios/fastlane/Appfile](mobile/ios/fastlane/Appfile) | #12 |
| 4 | Universal Links apuntan a `applinks:my.immich.app` | [mobile/ios/Runner/Runner.entitlements](mobile/ios/Runner/Runner.entitlements) y `RunnerProfile.entitlements` | #3 (requiere dominio propio) |
| 5 | CI de iOS depende de `immich-app/devtools` y secretos `PUSH_O_MATIC_*`; secretos de App Store Connect de origen desconocido | `build-mobile.yml` | #7, #12 |
| 6 | No hay ficha en App Store; el enlace de descarga lleva a la app de Immich (`id1613945652`) | `docs/docs/partials/_mobile-app-download.md` | #11 |
| 7 | **Sin probar:** el descubrimiento por mDNS usa `multicast_dns`, que abre el puerto 5353 directamente. Desde iOS 14 eso exige el permiso `com.apple.developer.networking.multicast`, que Apple aprueba a solicitud, y no está en los entitlements. Probablemente falle en iPhone; el descubrimiento por BLE y la IP manual no se ven afectados. | `server_discovery.service.dart` | — |

---

## Pasos

### Fase 0 — Decisiones y cuentas (sin código)

1. Conseguir una Mac con **macOS reciente y Xcode 26** (el CI usa Xcode 26.2), o contratar una Mac en la nube.
2. Inscribir a la organización en el [Apple Developer Program](https://developer.apple.com/programs/enroll/) (99 USD/año). Como organización se pide un **número D-U-N-S**; tramitarlo puede tardar días o semanas. Solo para probar en un iPhone propio basta un Apple ID gratuito, pero no sirve para repartir la app.
3. Anotar el **Team ID** de la cuenta: developer.apple.com → Account → Membership details (10 caracteres, p. ej. `ABCDE12345`).
4. Decidir cómo se va a repartir: Ad Hoc, TestFlight o App Store (tabla del inicio). Para el equipo interno, **TestFlight** es lo más cómodo.

### Fase 1 — Preparar la Mac

```bash
# Xcode desde la App Store, luego:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch

# Homebrew (https://brew.sh), luego:
brew install cocoapods

# Flutter 3.44.x (mismo rango que mobile/pubspec.yaml: >=3.44.6 <3.45.0)
# https://docs.flutter.dev/get-started/install/macos/mobile-ios
flutter doctor     # "Xcode" y "Flutter" sin errores
```

En Xcode → Settings → Accounts, iniciar sesión con el Apple ID de la cuenta de desarrollador.

### Fase 2 — Cambiar la identidad de Immich por la de Great Memories (en el repo)

Hacerlo en un PR para que aplique a todo el equipo:

1. [mobile/ios/Signing.xcconfig](mobile/ios/Signing.xcconfig): `GREAT_MEMORIES_TEAM_ID = <nuestro Team ID>`.
2. [mobile/ios/fastlane/Fastfile](mobile/ios/fastlane/Fastfile): `TEAM_ID = "<nuestro Team ID>"` y `CODE_SIGN_IDENTITY = "Apple Distribution: <Nombre legal de la organización> (#{TEAM_ID})"`.
3. [mobile/ios/fastlane/Appfile](mobile/ios/fastlane/Appfile): `apple_id` con el correo de la cuenta de la organización.
4. `Runner.entitlements` y `RunnerProfile.entitlements`: **quitar** la entrada `applinks:my.immich.app` hasta tener dominio propio (bloqueo #4). Si se deja, la firma puede fallar porque Apple no valida un dominio ajeno.

Mientras ese PR no exista, cada desarrollador puede usar su propia cuenta sin tocar el repo creando `mobile/ios/Signing.local.xcconfig` (ya ignorado por git):

```
GREAT_MEMORIES_TEAM_ID = ABCDE12345
GREAT_MEMORIES_BUNDLE_ID_PROD = com.<tunombre>.greatmemories
GREAT_MEMORIES_BUNDLE_ID_DEV = com.<tunombre>.greatmemoriesdev
GREAT_MEMORIES_GROUP_ID = group.com.<tunombre>.greatmemories
```

(Con una cuenta personal los bundle IDs deben ser únicos en todo Apple: `com.greatmemories.app` solo lo puede registrar un equipo.)

### Fase 3 — Primer build en un iPhone físico

```bash
git clone https://github.com/ludensproductions/great-memories.git
cd great-memories/mobile
flutter pub get
dart run easy_localization:generate -S ../i18n   # lib/generated/ no está en git
dart run bin/generate_keys.dart
cd ios && pod install && cd ..
open ios/Runner.xcworkspace                      # .xcworkspace, NO .xcodeproj
```

En Xcode:

1. Seleccionar el target **Runner** → Signing & Capabilities → confirmar que "Team" sea el nuestro. Repetir en **ShareExtension** y **WidgetExtension**.
2. Conectar el iPhone por cable. En el iPhone: Ajustes → Privacidad y seguridad → **Modo de desarrollador** → activar (pide reiniciar).
3. Cerrar Xcode y correr desde la terminal:

```bash
flutter devices   # debe aparecer el iPhone
flutter run       # versión debug (bundle com.greatmemories.app.dev.debug)
```

La primera vez, en el iPhone: Ajustes → General → VPN y gestión de dispositivos → confiar en el desarrollador.

### Fase 4 — Probar lo específico de iOS

Con el servidor corriendo ([DESARROLLO-LOCAL.md](DESARROLLO-LOCAL.md) o [CONFIGURACION-SERVIDOR.md](CONFIGURACION-SERVIDOR.md)), revisar en el iPhone:

- [ ] Login capturando `http://<IP>:2283` a mano.
- [ ] iOS pide el permiso de **red local** al conectar (si se niega, nada funciona: Ajustes → Great Memories → Red local).
- [ ] Descubrimiento por **BLE** encuentra el servidor.
- [ ] Descubrimiento por **mDNS**: si falla, es el bloqueo #7. Opciones: solicitar a Apple el [multicast entitlement](https://developer.apple.com/contact/request/networking-multicast), o cambiar el código a `bonsoir` (ya está en `pubspec.yaml` y usa la API Bonjour de Apple, que solo requiere `NSBonjourServices`, ya configurado).
- [ ] Respaldo de fotos en primer plano y en segundo plano.
- [ ] Compartir una foto desde la galería de iOS hacia la app (ShareExtension).
- [ ] Widget en la pantalla de inicio.
- [ ] Cola de subida offline con el servidor apagado.

### Fase 5 — Generar el `.ipa` y repartirlo

Requiere el Apple Developer Program. Desde `mobile/`:

```bash
# Ad Hoc: .ipa instalable en iPhones registrados (Fase 5a)
flutter build ipa --release --export-method ad-hoc

# App Store / TestFlight (Fase 5b)
flutter build ipa --release
```

Dónde queda:

| Ruta | Qué es |
|---|---|
| `mobile/build/ios/ipa/*.ipa` | **El archivo final** (el "APK de iOS"). |
| `mobile/build/ios/archive/Runner.xcarchive` | Archivo de Xcode; se abre con Xcode → Window → Organizer para subir o reexportar. |

**5a. Ad Hoc:** registrar el UDID de cada iPhone en developer.apple.com → Devices (el UDID se ve conectando el iPhone a la Mac, en Finder). Rehacer el build después de agregar equipos. El `.ipa` se instala con Apple Configurator, con Xcode (Window → Devices and Simulators → "+") o desde un enlace `itms-services://`.

**5b. TestFlight:**

1. En [App Store Connect](https://appstoreconnect.apple.com) → Apps → "+" → nueva app con bundle ID `com.greatmemories.app` (registrarlo antes en developer.apple.com → Identifiers junto con `com.greatmemories.app.ShareExtension`, `com.greatmemories.app.Widget` y el App Group `group.com.greatmemories.app.share`).
2. Subir el `.ipa` con la app **Transporter** (Mac App Store) o desde Xcode Organizer.
3. En App Store Connect → TestFlight: agregar testers internos (miembros de la cuenta, sin revisión) o externos (por correo o enlace público; primera build pasa una revisión breve).
4. Los testers instalan la app **TestFlight** en su iPhone y aceptan la invitación.

La versión sale de `version:` en `mobile/pubspec.yaml`. Cada subida a TestFlight necesita un número de build mayor (`--build-number <n>` si no se sube la versión).

### Fase 6 — Automatizar en CI (opcional, después de que funcione a mano)

1. App Store Connect → Users and Access → Integrations → **App Store Connect API** → generar una llave (`.p8`), anotar Key ID e Issuer ID.
2. En GitHub → Settings → Secrets and variables → Actions, reemplazar `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY` y `FASTLANE_TEAM_ID` con los de nuestra cuenta.
3. En `build-sign-ios` de `build-mobile.yml`, sustituir el paso `immich-app/devtools/actions/create-workflow-token` (secretos `PUSH_O_MATIC_*`) por `secrets.GITHUB_TOKEN` o un token propio (mismo bloqueo #7 que el resto del CI).
4. Correr el workflow; la lane `gha_testflight_dev` / `gha_release_prod` sube la build a TestFlight.

### Fase 7 — Publicar en App Store

1. Completar la ficha en App Store Connect: nombre, descripción, capturas (iPhone 6.9" y 6.5" como mínimo), ícono, categoría, **política de privacidad (URL pública obligatoria)**, formulario de privacidad de datos.
2. Dar a los revisores de Apple una cuenta y un servidor de prueba **accesible desde internet**: la app no hace nada sin servidor y es causa común de rechazo.
3. Enviar a revisión.
4. Ya publicada, reemplazar `id1613945652` en `docs/docs/partials/_mobile-app-download.md` por el ID nuevo (bloqueo #6).
5. Con dominio propio: volver a agregar Universal Links en los entitlements y publicar `apple-app-site-association` en ese dominio (bloqueo #4).

---

## Problemas comunes

| Síntoma | Solución |
|---|---|
| `No profiles for 'com.greatmemories.app' were found` | Team incorrecto en Signing & Capabilities, o bundle ID ya tomado por otro equipo: usar `Signing.local.xcconfig` con IDs propios |
| `Provisioning profile doesn't support the Associated Domains capability` | Quitar `applinks:my.immich.app` de los entitlements (Fase 2, paso 4), o la cuenta es gratuita |
| `pod install` falla / `CocoaPods not installed` | `brew install cocoapods`; si persiste: `cd ios && pod repo update && pod install` |
| Error por `lib/generated/...` faltante | Correr los dos comandos `dart run` de la Fase 3 |
| El iPhone no aparece en `flutter devices` | Activar Modo de desarrollador, confiar en la Mac al conectar el cable, desbloquear el iPhone |
| La app se cierra a los 7 días | Cuenta gratuita; reinstalar con `flutter run` o pasar al Apple Developer Program |
| "Unable to install" con el `.ipa` Ad Hoc | El UDID de ese iPhone no está registrado o se registró después del build |
| La app no encuentra el servidor en la red | Permiso de red local denegado (Ajustes → Great Memories → Red local), o bloqueo #7 (mDNS) |
