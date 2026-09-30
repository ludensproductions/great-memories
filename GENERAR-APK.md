# Generar un APK nuevo (Android)

Cómo compilar el APK de Great Memories en tu PC, dónde queda y cuál instalar.

Requisitos: el entorno de [DESARROLLO-LOCAL.md](DESARROLLO-LOCAL.md) (Flutter 3.44.x + Android Studio, `flutter doctor` sin errores en Android).

---

## El comando

Desde la raíz del repo, en PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File mobile\build-apk.ps1
```

Tarda 2–5 minutos. Al terminar imprime la ruta del APK, la versión y el tamaño:

```
APK listo (version 3.0.4+3057, 82 MB):
  C:\...\great-memories\mobile\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

Variante para celulares viejos, de 32 bits o emuladores x86 (un solo APK que sirve en cualquier celular, pero más pesado):

```powershell
powershell -ExecutionPolicy Bypass -File mobile\build-apk.ps1 -Universal
```

`-ExecutionPolicy Bypass` evita el bloqueo de Windows a scripts `.ps1` solo para esta ejecución; no cambia la configuración del sistema.

### Qué hace el script ([mobile/build-apk.ps1](mobile/build-apk.ps1))

1. `flutter pub get`
2. Genera las traducciones en `lib/generated/` (no está en git; sin esto no compila).
3. Vacía `build\app\outputs\flutter-apk\` para que ahí quede **solo** el APK nuevo.
4. `flutter build apk --release` (arm64, o universal con `-Universal`).
5. Imprime la ruta final y avisa si el APK quedó firmado con la llave debug.

---

## ¿Dónde queda el APK? (`apk/` vs `flutter-apk/`)

Todo está en `mobile\build\app\outputs\`:

| Carpeta | Quién la crea | ¿La uso? |
|---------|---------------|----------|
| **`flutter-apk\`** | Flutter copia aquí el APK final | ✅ **Sí. Es la única que importa.** De aquí se instala o se comparte. |
| `apk\release\`, `apk\debug\` | Gradle (el build nativo de Android), como paso intermedio | ❌ No. Es salida interna de Gradle. Flutter la copia a `flutter-apk\`. |
| `mapping\`, `native-debug-symbols\`, `logs\`… | Gradle | ❌ No, salvo para depurar crashes ofuscados. |

**Por qué no se unifican:** ninguna de las dos está en el repo. Ambas viven dentro de `mobile\build\`, que está en `.gitignore`, y las crean Flutter y Gradle en cada build. Si se borran, vuelven a aparecer en el siguiente. Moverlas implicaría modificar el plugin de Gradle de Flutter, lo que no vale la pena. El CI del proyecto también toma el APK de `flutter-apk\` ([.github/workflows/build-mobile.yml](.github/workflows/build-mobile.yml)).

**De dónde venía el ruido:** `flutter-apk\` **acumula** APKs de builds anteriores. Por ejemplo, un `app-armeabi-v7a-release.apk` de hace días junto al arm64 de hoy, o un `app-debug.apk` de un `flutter run` viejo. Así no se sabía cuál era el bueno. El script vacía esa carpeta antes de compilar. Si compilas sin el script, fíjate en la fecha de modificación del archivo.

### ¿Qué archivo instalo?

| Archivo en `flutter-apk\` | Para qué |
|---|---|
| `app-arm64-v8a-release.apk` | **El normal.** Cualquier celular Android de los últimos ~8 años. Es el que genera el script por defecto. |
| `app-release.apk` | Universal (`-Universal`). Sirve en cualquier celular o emulador; pesa más. |
| `app-armeabi-v7a-release.apk` / `app-x86_64-release.apk` | Celulares de 32 bits / emuladores. Solo aparecen si compilas a mano con `--split-per-abi` sin limitar plataformas. |
| `app-debug.apk` | Lo genera `flutter run`. **No compartir**: es lento, pesa el doble y se instala como otra app (`com.greatmemories.app.debug`). |
| `*.sha1` | Checksum del APK. No se instala. |

---

## Instalar el APK

- **Por USB:** `adb install -r mobile\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk` (`-r` actualiza conservando los datos).
- **Sin cable:** copiar el `.apk` al celular (WhatsApp, Drive, etc.), abrirlo y permitir "Instalar apps desconocidas".

---

## Firma: por qué a veces "la app no se instala"

Android solo acepta actualizar una app si el APK nuevo está firmado **con la misma llave** que el instalado.

- Si existe `mobile\android\key.jks` (o `mobile\android\key.properties` apuntando a una llave), el APK se firma con la **llave oficial**. Esa llave no está en el repo y no se debe subir.
- Si no existe (el caso normal en una PC de desarrollo), el APK se firma con la **llave debug de esa PC** (`%UserProfile%\.android\debug.keystore`). El script avisa en amarillo.

Consecuencias:

| Situación | Resultado |
|---|---|
| Instalaste un APK de tu PC y actualizas con otro de tu PC | ✅ Actualiza |
| Instalaste uno de la PC de otro dev (o de CI) y actualizas con el tuyo | ❌ "App no instalada" / `INSTALL_FAILED_UPDATE_INCOMPATIBLE` → desinstalar primero (**se pierden los datos locales de la app**, no las fotos del servidor) |
| El APK nuevo tiene un `versionCode` menor que el instalado | ❌ `INSTALL_FAILED_VERSION_DOWNGRADE` → subir la versión (abajo) o desinstalar |

Para builds que se reparten a usuarios reales, usar el APK que publica CI (firmado con la llave oficial). Los APK locales son para pruebas.

---

## Versión del APK

Sale de `version:` en [mobile/pubspec.yaml](mobile/pubspec.yaml): `3.0.4+3057` → versionName `3.0.4`, versionCode `3057`. No editarla a mano para un release: el comando de release del repo (`mise release`) la sube en todos los paquetes a la vez. Para una prueba puntual se puede forzar sin tocar el archivo compilando a mano:

```powershell
cd mobile
flutter build apk --release --split-per-abi --target-platform android-arm64 --build-number 3058
```

---

## Problemas comunes

| Síntoma | Solución |
|---|---|
| `... no se puede cargar porque la ejecución de scripts está deshabilitada` | Usar el comando completo con `powershell -ExecutionPolicy Bypass -File ...` |
| `El argumento 'mobile\build-apk.ps1' ... no existe` | Correrlo desde la raíz del repo, no desde `mobile\` (ahí sería `-File build-apk.ps1`) |
| `flutter` / `dart` no se reconoce | Flutter no está en el `PATH`; ver [DESARROLLO-LOCAL.md](DESARROLLO-LOCAL.md) |
| Falla por versión del SDK en `pub get` | Usar Flutter 3.44.x (`flutter --version`) |
| Error de Gradle / licencias de Android | `flutter doctor --android-licenses` y `flutter doctor` |
| El build se queda raro después de cambiar de rama | `cd mobile; flutter clean` y volver a correr el script |
| "App no instalada" al actualizar | Ver [Firma](#firma-por-qué-a-veces-la-app-no-se-instala) |
