# Rebranding a Great Memories — pendientes de servicios externos

Este documento rastrea puntos donde el producto todavía depende de dominios,
cuentas, repos o infraestructura propiedad de Immich. Son cosas que **no se
pueden arreglar solo editando código** en la mayoría de los casos — requieren
una acción administrativa (dar de alta un dominio propio, crear una cuenta de
desarrollador, generar credenciales nuevas, montar infraestructura propia)
antes de poder actualizar el código/config para que apunte a Great Memories.

Mientras no se resuelvan, se deja constancia aquí de qué falta y qué pasos
seguir, en vez de dejarlo así indefinidamente.

## Orden de prioridad

| # | Punto | Severidad | Afecta a |
|---|-------|-----------|----------|
| 1 | [Instalador y Docker Compose](#1-instalador-y-docker-compose-apuntan-a-releases-de-immich) | 🟡 En progreso | Todo usuario que instala/actualiza el server |
| 2 | [Imágenes de contenedor (GHCR)](#2-imágenes-de-contenedor-ghcr-propiedad-de-immich-app) | 🔴 Crítico | Todo despliegue (server, ML, Postgres) |
| 3 | [Deep links / Universal Links móviles](#3-deep-links--universal-links-apuntan-a-myimmichapp) | 🔴 Crítico | Usuarios de la app móvil |
| 4 | [Enlaces generados por el backend](#4-el-backend-genera-en-runtime-enlaces-a-immich) | 🔴 Crítico | Usuarios que ven "About", errores, o descargan el APK |
| 5 | [Terraform de documentación](#5-infraestructura-terraform-de-docs-apunta-a-docsimmichapp) | 🔴 Crítico | Publicación de la documentación propia |
| 6 | [Flujo de compra/licencia](#6-flujo-de-compralicencia-en-buyimmichapp) | 🔴 Crítico | Monetización del proyecto |
| 7 | [GitHub Actions de `immich-app/devtools`](#7-cicd-depende-de-github-actions-de-immich-appdevtools) | 🟠 Operativo | Pipeline de CI/CD (build, release) |
| 8 | [Weblate compartido](#8-weblate-posiblemente-compartido-con-immich) | 🟠 Operativo | Flujo de traducciones |
| 9 | [F-Droid vía FUTO](#9-f-droid-publica-con-identidad-de-immich) | 🟠 Operativo | Distribución en F-Droid |
| 10 | [security.txt](#10-securitytxt-dirige-reportes-a-immich) | ✅ Resuelto | Reportes de vulnerabilidades |
| 11 | [Ficha propia en Apple App Store](#11-ficha-propia-en-apple-app-store) | 🟡 Pendiente de confirmar | Descarga en iOS |
| 12 | [Credenciales de firma/publicación](#12-credenciales-de-firmapublicación-en-build-mobileyml) | 🟡 Pendiente de confirmar | Builds firmados de iOS/Android |

## Plan de ejecución

Contexto confirmado al momento de escribir este plan (2026-08-19):
- **Sí existe** una organización propia en GitHub: `github.com/ludensproductions`.
  Great Memories pertenecerá a esa organización.
- **No existe todavía** un dominio propio para Great Memories (ni para docs, ni
  para deep links).

El orden de prioridad de la tabla de arriba es por severidad, pero varios
puntos críticos tienen dependencias entre sí — no se pueden resolver en
cualquier orden porque unos destraban a otros. Este plan reordena el trabajo
según esas dependencias reales, para poder avanzar paso a paso sin quedar
bloqueado a mitad de un punto por falta de un requisito previo.

```
Paso 0 → Paso 1 → Paso 2 → Paso 3 → Paso 4 → Paso 5 → Paso 6
(quick     (repo/      (registro    (comprar    (deep      (operativos   (negocio:
 win)      releases    de           dominio     links +    de CI/        compra +
           propias)    contenedores propio)     docs vía   distribución) tiendas)
                       propio)                  dominio)
```

### Paso 0 — Quick win: punto 10 (`security.txt`) ✅ Hecho (2026-08-20)

Hazlo primero y ya. No depende de nada del resto del plan, es editar un solo
archivo, y es completamente reversible. Sirve además para validar el flujo de
"detectar → documentar en este archivo → resolver → marcar como hecho" antes
de meterse a los puntos grandes.

**Resuelto:** `web/static/.well-known/security.txt` ya apunta a
`github.com/ludensproductions/great-memories` (Policy y Security Advisories) y
a `security@greatmemories.app` como contacto. Ese correo es un **placeholder**
sobre un dominio que todavía no existe (ver Paso 3) — hay que confirmarlo o
rotarlo a un correo real en cuanto exista el dominio propio o se defina un
contacto alternativo.

### Paso 1 — Repo y releases propias en `ludensproductions` (base de los puntos 1, 2 y parte del 4) 🟡 En progreso (2026-08-20)

Ya existe la organización, así que este paso es solo trabajo de repo/CI, sin
gestiones externas:
1. ✅ **Confirmado:** las releases públicas de Great Memories viven en el mismo
   repo actual, `github.com/ludensproductions/great-memories` (es el `origin`
   git de este checkout).
2. ✅ **Verificado:** `prepare-release.yml` (job `prepare_release`, líneas
   154-170) ya adjunta `docker/docker-compose.yml`,
   `docker/docker-compose.rootless.yml`, `docker/example.env`,
   `docker/hwaccel.ml.yml`, `docker/hwaccel.transcoding.yml`,
   `docker/prometheus.yml` y el `.apk` como assets del release vía
   `softprops/action-gh-release`. No requiere cambios: al correr el workflow en
   `ludensproductions/great-memories` publicará esos assets ahí directamente.
   (`packages/scripts/src/commands/release.ts` solo bumpea versiones; la única
   URL de Immich que genera es `archive.immich.app` para versiones archivadas,
   que corresponde al punto 5, no a este.)
3. ✅ **Hecho:** actualizado `install.sh` para descargar desde
   `github.com/ludensproductions/great-memories/releases/latest/download/...`
   en vez de `immich-app/immich`. También actualizados los comentarios
   `# Make sure to use the docker-compose.yml of the current release` en
   `docker/docker-compose.yml`, `docker-compose.prod.yml`,
   `docker-compose.rootless.yml`, `docker-compose.dev.yml` y `docker/README.md`
   para apuntar al mismo repo.
4. ⚠️ **Pendiente real — no confundir con "hecho":** todavía **no existe ningún
   release publicado** en `ludensproductions/great-memories` con esos assets.
   `install.sh` apunta a `releases/latest/download/...`, que **fallará** hasta
   que se dispare `prepare-release.yml` (o un release manual) al menos una vez
   en ese repo. No anunciar/recomendar `install.sh` a usuarios finales hasta
   confirmar que existe un release con los assets adjuntos.
5. Nota: las imágenes de contenedor (`ghcr.io/immich-app/...` en los mismos
   `docker-compose*.yml`) **no se tocaron** — eso es el punto 2 / Paso 2, que
   depende de tener el registro GHCR propio primero.

### Paso 2 — Registro de contenedores propio bajo `ludensproductions` (punto 2)

GHCR funciona igual bajo la organización de GitHub que ya existe — no se
necesita Docker Hub ni ninguna cuenta nueva:
1. Activar/usar GHCR en `ludensproductions` y crear un workflow de CI que
   construya y publique `great-memories-server`,
   `great-memories-machine-learning` y la imagen de Postgres usada
   (`ghcr.io/ludensproductions/...`).
2. Con el registro propio y las releases del paso 1 ya funcionando, **ahora sí
   se puede cerrar el punto 1 completo**: actualizar `install.sh` y todos los
   `docker-compose*.yml` para apuntar a `ludensproductions` en vez de
   `immich-app`.
3. Esto también resuelve la parte de `versionUrl` / `getApkLinks` del punto 4
   que depende de las releases de GitHub (no de docs).

### Paso 3 — Comprar el dominio propio (desbloquea puntos 3 y 5)

Este es el único paso de este plan que requiere una gestión externa real
(compra + configuración DNS) y no se puede evitar: los puntos 3 (deep links) y
5 (Terraform de docs) están duros bloqueados sin un dominio propio.
1. Decidir y comprar el dominio (ej. `greatmemories.app` o el que se elija).
2. Configurar la zona DNS (Cloudflare u otro proveedor) bajo control de la
   organización.

### Paso 4 — Con dominio en mano: cerrar puntos 3, 5, y el resto del 4

1. Publicar `.well-known/apple-app-site-association` y
   `.well-known/assetlinks.json` en el dominio propio, y actualizar
   `AndroidManifest.xml`, `Runner.entitlements`, `RunnerProfile.entitlements` y
   `main.dart:187` (punto 3).
2. Apuntar `domain.tf` de los módulos Terraform de docs al dominio propio y
   desplegar (punto 5).
3. Reemplazar los enlaces a `docs.immich.app` en `constants.ts` y
   `storage.service.ts` por la documentación propia ya desplegada (cierre del
   punto 4).

### Paso 5 — Operativos de CI/distribución (puntos 7, 8, 9)

No bloquean a usuarios finales, así que quedan después de lo anterior:
- Punto 7: evaluar dependencia de `immich-app/devtools` y decidir entre
  GitHub App propia o fork de las actions.
- Punto 8: confirmar si el proyecto en Weblate es independiente o un
  componente dentro del proyecto de Immich, y migrar si hace falta.
- Punto 9: cambiar el email de commit usado en el workflow de F-Droid.

### Paso 6 — Decisiones de negocio (puntos 6, 11, 12)

Estos no dependen de infraestructura técnica sino de decisiones de negocio
(¿va a monetizarse Great Memories? ¿ya existe o se va a crear una cuenta Apple
Developer propia?). Pueden resolverse en paralelo a cualquiera de los pasos
anteriores en cuanto haya claridad:
- Punto 6: definir modelo de monetización y flujo de compra propio (o quitar
  la sección si no aplica).
- Punto 11: dar de alta la ficha en App Store Connect.
- Punto 12: confirmar o rotar las credenciales de firma de iOS/Android.

---

## 1. Instalador y Docker Compose apuntan a releases de Immich 🟡 En progreso (2026-08-20)

**Estado actual:** [install.sh:75](install.sh#L75) ya descarga
`docker-compose.yml` y `.env` desde
`https://github.com/ludensproductions/great-memories/releases/latest/download/...`.
Los comentarios en `docker/docker-compose*.yml` (default, rootless, prod, dev) y
[docker/README.md:3](docker/README.md#L3) ya apuntan a ese mismo repo.
**Pendiente:** todavía no existe ningún release publicado ahí con esos assets
adjuntos, así que la URL `releases/latest/download/...` fallará (404) hasta que
se corra `prepare-release.yml` (o se publique un release manual) al menos una
vez en `ludensproductions/great-memories`.

**Por qué bloquea:** el script de instalación oficial de Great Memories —el que
se recomienda a cualquier usuario nuevo— apunta ya al repositorio correcto, pero
sin un release publicado ahí la instalación falla directamente. No se debe
recomendar `install.sh` a usuarios finales hasta confirmar que el primer release
con esos assets existe.

**Qué falta implementar:**
1. ~~Publicar releases propias de Great Memories en
   `github.com/<org>/great-memories`~~ → confirmado: es
   `github.com/ludensproductions/great-memories` (ya es el `origin` de este
   repo). Falta que corra `prepare-release.yml` (o un release manual) al menos
   una vez ahí para que existan los assets.
2. ~~Actualizar `install.sh` para apuntar a
   `github.com/<org-great-memories>/great-memories/releases/latest/download/...`~~
   → hecho.
3. ~~Actualizar los comentarios/instrucciones en todos los
   `docker/docker-compose*.yml` y en `docker/README.md`~~ → hecho (solo la URL
   de descarga; el link a `docs.immich.app/install/docker-compose` en esos
   mismos archivos es el punto 4/5, pendiente de dominio propio).
4. ~~Verificar que el pipeline de release (`prepare-release.yml`,
   `release.ts`)~~ → verificado: `prepare-release.yml` líneas 154-170 ya adjunta
   los assets correctos vía `softprops/action-gh-release`, sin cambios de
   código necesarios. Falta solo **ejecutarlo** en el repo propio.

## 2. Imágenes de contenedor (GHCR) propiedad de `immich-app`

**Estado actual:** server, machine-learning y Postgres se descargan de
`ghcr.io/immich-app/immich-server`, `ghcr.io/immich-app/immich-machine-learning`
y `ghcr.io/immich-app/postgres` en `docker/docker-compose.yml`,
`docker-compose.rootless.yml`, `docker-compose.prod.yml`, `docker-compose.dev.yml`.
El propio `server/Dockerfile` y `server/Dockerfile.dev` usan
`ghcr.io/immich-app/base-server-dev` / `base-server-prod` como imagen base de
build.

**Por qué bloquea:** todo despliegue de Great Memories —incluyendo el de
cualquier usuario final— descarga binarios publicados bajo la cuenta de GHCR de
`immich-app`. Great Memories no controla ese registro: si Immich borra, renombra
o restringe esas imágenes, ningún usuario puede desplegar ni actualizar Great
Memories.

**Qué falta implementar:**
1. Configurar un registro de contenedores propio (GHCR bajo la org de Great
   Memories, o Docker Hub) y un workflow de CI que construya y publique
   `great-memories-server`, `great-memories-machine-learning` y la imagen de
   Postgres usada, replicando lo que hoy hacen los workflows de Immich.
2. Para las imágenes base de build (`base-server-dev`/`base-server-prod`),
   evaluar si se puede seguir dependiendo de las de Immich (son solo imágenes de
   build, no runtime público) o si conviene también tener una copia propia para
   evitar el riesgo de que Immich las retire.
3. Una vez publicadas las imágenes propias, actualizar los `image:` en todos los
   `docker-compose*.yml`, `server/Dockerfile`, `server/Dockerfile.dev`,
   `server/test/medium/globalSetup.ts`, `e2e/docker-compose.yml` y los workflows
   de CI (`test.yml`, `close-duplicates.yml`) para apuntar al registro propio.
4. Actualizar `renovate.json` para trackear las imágenes propias en vez de
   `ghcr.io/immich-app/postgres` y `ghcr.io/immich-app/base-server-*`.
5. Actualizar la documentación que enseña estos comandos a usuarios finales
   (`docs/docs/install/upgrading.md`, `docs/docs/guides/remote-machine-learning.md`,
   `docs/docs/features/ml-hardware-acceleration.md`,
   `docs/docs/features/hardware-transcoding.md`,
   `docs/docs/features/command-line-interface.md`).

## 3. Deep links / Universal Links apuntan a `my.immich.app`

**Estado actual:** `my.immich.app` está verificado como App Link
(`autoVerify="true"`) en
[mobile/android/app/src/main/AndroidManifest.xml:122-145](mobile/android/app/src/main/AndroidManifest.xml#L122-L145)
y como Associated Domain en `mobile/ios/Runner/Runner.entitlements` y
`RunnerProfile.entitlements`. La lógica de enrutamiento en
[mobile/lib/main.dart:187](mobile/lib/main.dart#L187) compara el host del deep
link literalmente contra `"my.immich.app"`.

**Por qué bloquea:** es un dominio que pertenece a Immich, no a Great Memories.
Funciona hoy porque Immich mantiene el archivo `apple-app-site-association` /
`assetlinks.json` en ese dominio apuntando (probablemente) a la app original de
Immich, no a Great Memories — es decir, este comportamiento es frágil incluso
si "funciona" en algunos casos, y se rompe en cuanto Immich cambie esa
configuración.

**Qué falta implementar:**
1. Adquirir un dominio propio para Great Memories (ej. `my.greatmemories.app` o
   el que se decida) y publicar ahí los archivos de verificación
   `.well-known/apple-app-site-association` (iOS) y
   `.well-known/assetlinks.json` (Android) apuntando al bundle ID
   `com.greatmemories.app` y al Team ID/firma de Great Memories.
2. Reemplazar `my.immich.app` por el dominio propio en `AndroidManifest.xml`,
   `Runner.entitlements`, `RunnerProfile.entitlements` y la comparación en
   `main.dart:187`.
3. Actualizar el test `mobile/test/services/deep_link_service_test.dart:107` que
   fija la URL a `https://my.immich.app$path`.
4. Actualizar cualquier referencia visible al usuario que use ese host, incluido
   el link de Obtainium en `_mobile-app-download.md:6`
   (`https://my.immich.app/utilities`).

## 4. El backend genera en runtime enlaces a Immich

**Estado actual:** `server/src/services/server.service.ts:50` construye
`versionUrl` como `https://github.com/immich-app/immich/releases/tag/${version}`
(mostrado en el modal "About"). `server.service.ts:58` (`getApkLinks()`)
construye URLs de descarga de APK desde
`https://github.com/immich-app/immich/releases/download/v...`.
`server/src/constants.ts:18-20` (`ErrorMessages`) y
`server/src/services/storage.service.ts:19` muestran mensajes de error al
admin con enlaces a `docs.immich.app`. `server/src/main.ts:180` tiene un mensaje
de deprecación que enlaza a un release tag de `immich-app/immich`.

**Por qué bloquea:** el propio servidor de Great Memories, en tiempo de
ejecución, le dice a los usuarios/administradores que vayan a GitHub o a la
documentación de Immich — no solo es un problema de código estático, es
contenido que se les muestra activamente.

**Qué falta implementar:**
1. Cambiar `versionUrl` y `getApkLinks()` en `server.service.ts` para que
   apunten al repositorio y a las releases propias de Great Memories (depende
   de que el punto 1 ya tenga releases publicadas ahí).
2. Reemplazar los enlaces a `docs.immich.app` en `constants.ts` y
   `storage.service.ts` por la URL de la documentación propia de Great Memories
   (depende del punto 5).
3. Actualizar el mensaje de deprecación en `main.ts:180`.
4. Auditar el resto de `server/src` por más strings `immich-app` o
   `docs.immich.app` que no hayan salido en el barrido inicial (el reporte de
   servicios externos no fue exhaustivo a nivel de cada mensaje de error
   individual).

## 5. Infraestructura Terraform de docs apunta a `docs.immich.app`

**Estado actual:** `deployment/modules/cloudflare/docs/domain.tf` y
`deployment/modules/cloudflare/docs-release/domain.tf` definen literalmente
`domain = "docs.immich.app"`. `docs/docusaurus.config.js:10` tiene
`url: 'https://docs.immich.app'` como URL canónica del sitio, y
`docusaurus.config.js:98` enlaza el botón "Home" a `https://immich.app/`.
`packages/scripts/src/commands/release.ts:219` genera URLs de versiones
archivadas como `https://docs.v${nextVersion}.archive.immich.app`, y
`docs/static/archived-versions.json` tiene decenas de entradas con ese patrón.

**Por qué bloquea:** Great Memories no tiene todavía una URL propia de
documentación desplegada vía IaC — todo el pipeline de Terraform está
literalmente configurado para desplegar en un dominio que pertenece a Immich.
Mientras no se corrija, no hay forma de que "publicar los docs de Great
Memories" resulte en un dominio distinto al de Immich.

**Qué falta implementar:**
1. Registrar un dominio propio para la documentación de Great Memories (ej.
   `docs.greatmemories.app`) y una zona en Cloudflare (u otro proveedor) bajo
   control de Great Memories.
2. Actualizar `domain.tf` en ambos módulos (`docs` y `docs-release`) para usar
   el dominio propio, y aplicar el cambio de infraestructura (`terraform
   apply`) — esto es una acción con efecto en servicios reales, coordinarla
   con quien administra la cuenta de Cloudflare.
3. Actualizar `docusaurus.config.js` (`url` y el link del navbar) para reflejar
   el dominio y sitio propios.
4. Decidir qué hacer con el histórico de `archived-versions.json` y las URLs
   `archive.immich.app` generadas por `release.ts:219` — si Great Memories no
   tiene ese archivo histórico, esas entradas deben quitarse o el script debe
   generar el nuevo dominio de archivo propio.
5. Corregir `docs/static/_redirects` (redirección a `awesome.immich.app`) si
   Great Memories no tiene un proyecto "awesome" propio equivalente, o apuntarlo
   a uno propio si se crea.

## 6. Flujo de compra/licencia en `buy.immich.app`

**Estado actual:** [docs/docs/overview/support-the-project.md:21](docs/docs/overview/support-the-project.md#L21)
enlaza `[purchase Great Memories](https://buy.immich.app)`.

**Por qué bloquea:** el único flujo de monetización/compra visible en la
documentación depende de un backend de checkout que pertenece a Immich. Great
Memories no puede procesar pagos propios ni tiene control sobre precios,
catálogo o datos de esa compra.

**Qué falta implementar:**
1. Definir el modelo de monetización propio de Great Memories (si aplica) y
   montar un flujo de compra/checkout propio (Stripe, Paddle, LemonSqueezy, o
   lo que se decida).
2. Reemplazar el enlace `buy.immich.app` por el flujo propio en
   `support-the-project.md`.
3. Si Great Memories no planea cobrar por el producto, quitar esa sección en
   vez de dejar un enlace roto o ajeno.

## 7. CI/CD depende de GitHub Actions de `immich-app/devtools`

**Estado actual:** múltiples workflows (`weblate-lock.yml`,
`prepare-release.yml`, `build-mobile.yml`, `merge-translations.yml`) usan
acciones compuestas alojadas en `immich-app/devtools`
(`create-workflow-token`, `pre-job`, `use-mise`, `sticky-comment`,
`success-check`) autenticadas con secretos `PUSH_O_MATIC_APP_CLIENT_ID` /
`PUSH_O_MATIC_APP_KEY`, que corresponden a una GitHub App
(`immich-push-o-matic`) de la organización Immich.

**Por qué bloquea:** el pipeline de CI/CD de Great Memories no es autónomo —
depende de una GitHub App y de actions mantenidas por la organización
`immich-app`. Si Immich revoca el acceso, cambia permisos, o elimina esas
actions, los builds y releases de Great Memories dejan de funcionar sin que
Great Memories pueda arreglarlo por su cuenta.

**Qué falta implementar:**
1. Evaluar si `immich-app/devtools` es público y de uso libre (en cuyo caso el
   riesgo es solo "Immich podría cambiarlo sin avisar") o si depende de
   permisos/tokens exclusivos de la organización Immich (riesgo alto).
2. Si depende de permisos exclusivos: crear una GitHub App propia de Great
   Memories equivalente a `immich-push-o-matic` (mismo propósito: token de
   corta duración para operaciones de CI), o forkear `immich-app/devtools` bajo
   la organización de Great Memories y apuntar los workflows ahí.
3. Reemplazar las referencias a `immich-app/devtools/actions/*` en
   `weblate-lock.yml`, `prepare-release.yml`, `build-mobile.yml` y
   `merge-translations.yml` por la versión propia.
4. Sustituir los secretos `PUSH_O_MATIC_APP_CLIENT_ID`/`PUSH_O_MATIC_APP_KEY`
   por las credenciales de la GitHub App propia.

## 8. Weblate posiblemente compartido con Immich

**Estado actual:** `merge-translations.yml` usa
`WEBLATE_HOST: 'https://hosted.weblate.org'` y
`WEBLATE_COMPONENT: 'great-memories/great-memories'`. El componente ya se
renombró, pero falta confirmar si `great-memories` es un **proyecto**
independiente en Weblate o un **componente dentro del proyecto `immich`**.
`docs/docs/overview/support-the-project.md:13` enlaza literalmente a
`https://hosted.weblate.org/projects/immich/immich/` (proyecto de Immich, no de
Great Memories).

**Por qué bloquea:** si el componente vive dentro del proyecto Weblate de
Immich, los mantenedores de Immich tienen acceso administrativo a las
traducciones de Great Memories, y cualquier cambio de configuración que hagan
en su proyecto puede afectar el pipeline de traducciones de Great Memories.

**Qué falta implementar:**
1. Verificar en la consola de Weblate si `great-memories/great-memories` es un
   proyecto propio o un componente anidado en `immich/*`.
2. Si es un componente dentro del proyecto de Immich: crear un proyecto Weblate
   independiente para Great Memories, migrar las traducciones existentes, y
   actualizar `WEBLATE_COMPONENT` en `merge-translations.yml` y
   `weblate-lock.yml`.
3. Corregir el enlace en `support-the-project.md:13` para que apunte al
   proyecto propio de Great Memories en Weblate.
4. Revisar `docs/docs/developer/translations.md`, `CONTRIBUTING.md` y los
   `readme_i18n/README_*.md` por más enlaces al proyecto Weblate de Immich.

## 9. F-Droid publica con identidad de Immich

**Estado actual:** `.github/workflows/fdroid.yml` publica el APK en
`gitlab.futo.org/fdroid/repo-v2.git` bajo `apps/Great Memories/index.yml`,
usando `bot@immich.app` como email de commit (líneas ~45, 51, 54).

**Por qué bloquea:** aunque el repo F-Droid es de un tercero (FUTO, no Immich),
el email de autor/commit usado para publicar Great Memories sigue siendo un
correo de dominio Immich, lo cual es inconsistente y puede generar confusión o
problemas de atribución en el historial de ese repositorio de terceros.

**Qué falta implementar:**
1. Crear una dirección de correo propia de Great Memories para uso de bots de
   CI (ej. `bot@greatmemories.app` o el dominio que se use).
2. Actualizar `fdroid.yml` para usar esa dirección en los commits.
3. Confirmar con FUTO/F-Droid si el listing debe re-solicitarse o transferirse
   de identidad de mantenedor, ya que estos repos comunitarios a veces requieren
   verificación del nuevo mantenedor.

## 10. `security.txt` dirige reportes a Immich ✅ Resuelto (2026-08-20)

**Estado anterior:** `web/static/.well-known/security.txt` tenía
`Contact: mailto:security@immich.app` y enlaces a
`github.com/immich-app/immich/security/advisories/new`.

**Por qué bloqueaba:** cualquier investigador de seguridad que encuentre una
vulnerabilidad en Great Memories y siga las buenas prácticas (revisar
`security.txt`) terminaría reportándola al equipo de seguridad de Immich, que
no tiene ni el contexto ni la responsabilidad de gestionar vulnerabilidades de
Great Memories. Esto era un riesgo real: reportes de seguridad podrían
perderse o tardar en llegar al equipo correcto.

**Qué se implementó:**
1. `web/static/.well-known/security.txt` ahora apunta `Policy` y `Contact` (el
   enlace de GitHub Security Advisories) a
   `github.com/ludensproductions/great-memories`.
2. Se usó `mailto:security@greatmemories.app` como contacto — **es un
   placeholder** sobre un dominio que aún no existe (Paso 3 de este plan). Debe
   confirmarse o rotarse a un correo real (ej. uno bajo `ludensproductions` o
   el que se decida) en cuanto exista dirección definitiva.
3. Pendiente opcional: dar de alta un programa formal de "security advisories"
   en GitHub si no existe ya en `ludensproductions/great-memories`.

---

## 11. Ficha propia en Apple App Store

**Estado actual:** [docs/docs/partials/_mobile-app-download.md:3](docs/docs/partials/_mobile-app-download.md#L3)
enlaza a `https://apps.apple.com/us/app/great-memories/id1613945652`. El ID numérico
`1613945652` es el ID de App Store histórico de **Immich**, no de Great Memories.
El slug de la URL dice "great-memories" pero el ID real sigue resolviendo a la
ficha de Immich en App Store Connect.

**Por qué bloquea:** cualquier usuario de iOS que use ese enlace termina en la
página de la app de Immich, no en una app propia de Great Memories.

**Qué falta implementar:**
1. Dar de alta una cuenta de Apple Developer Program a nombre de la organización
   que publica Great Memories (si no existe ya una distinta a la de Immich).
2. Crear una nueva app en App Store Connect con bundle ID `com.greatmemories.app`
   (el bundle ID en [mobile/android/app/build.gradle:40](mobile/android/app/build.gradle#L40)
   ya usa este identificador para Android; en iOS hay que confirmar que
   `mobile/ios/Runner.xcodeproj` / `ios/Runner/Info.plist` use el mismo bundle id
   y no el histórico de Immich).
3. Completar la ficha de la app (nombre, capturas, descripción, ícono, política de
   privacidad) y enviarla a revisión de Apple.
4. Una vez aprobada y publicada, Apple asigna un nuevo Apple ID numérico para
   Great Memories. Reemplazar `id1613945652` en
   [docs/docs/partials/_mobile-app-download.md](docs/docs/partials/_mobile-app-download.md)
   por ese nuevo ID.
5. Verificar el Associated Domain `applinks:my.immich.app` en
   [mobile/ios/Runner/Runner.entitlements](mobile/ios/Runner/Runner.entitlements) y
   `RunnerProfile.entitlements` — deben apuntar a un dominio propio de Great
   Memories una vez que exista (ver punto 3 de este documento), ya que Apple
   valida el archivo `apple-app-site-association` contra ese dominio al
   revisar Universal Links.

**Hasta que esto no esté hecho:** el enlace de descarga de iOS seguirá
redirigiendo a la ficha de Immich. Dejar comentado o marcado visualmente en la
propia página de descargas (o quitar temporalmente el enlace de Apple Store) es
preferible a dejar un enlace que confunde al usuario, pero la solución real es
completar los pasos de arriba.

## 12. Credenciales de firma/publicación en `build-mobile.yml`

**Estado actual:** [.github/workflows/build-mobile.yml](.github/workflows/build-mobile.yml)
usa los secretos `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID`,
`APP_STORE_CONNECT_API_KEY` (líneas 23-28, usados en el job `build-sign-ios`,
paso "Create API Key", línea 255) y `FASTLANE_TEAM_ID` (línea 33, usado en el
paso "Build and deploy to TestFlight", línea 294) para firmar y subir builds de
iOS a TestFlight/App Store. También usa `KEY_JKS`, `ALIAS`,
`ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD` (líneas 15-22) para firmar el
APK de Android.

No es posible verificar desde el código a qué cuenta pertenecen estos secretos,
porque su *valor* vive en la configuración de GitHub Actions (Settings → Secrets),
no en el repo.

**Por qué bloquea:** si estos secretos todavía son las credenciales de firma de
Immich (su cuenta de Apple Developer, su Team ID de Fastlane, su keystore de
Android), entonces cualquier build "de producción" que genere este pipeline se
firmará y publicará con la identidad de Immich, no de Great Memories — aun
cuando el bundle ID ya diga `com.greatmemories.app`. Un mismatch entre bundle ID
nuevo y team/cuenta de firma antigua puede además hacer fallar el build o el
alta en las tiendas.

**Qué falta implementar:**
1. Confirmar con quien administra los secretos del repo (Settings → Secrets and
   variables → Actions) si `APP_STORE_CONNECT_API_KEY*` y `FASTLANE_TEAM_ID`
   corresponden a la cuenta de Apple Developer de Great Memories o todavía a la
   de Immich/Alex Tran.
2. Si son de Immich: generar una nueva API Key en App Store Connect
   (Users and Access → Integrations → App Store Connect API) bajo la cuenta de
   Great Memories, y obtener el nuevo `Team ID` desde el perfil de la cuenta.
3. Generar un keystore Android propio (`key.jks`) para Great Memories si el
   actual (`KEY_JKS`/`ALIAS`/`ANDROID_KEY_PASSWORD`/`ANDROID_STORE_PASSWORD`) es
   el keystore original de Immich — importante notar que **el keystore de
   Android no se puede cambiar después de la primera publicación** sin perder
   la posibilidad de actualizar la app ya instalada por los usuarios, así que
   esta decisión debe tomarse antes del primer release público bajo el nuevo
   bundle ID.
4. Actualizar los secretos en GitHub (mismo nombre de secreto, valor nuevo) para
   que `build-mobile.yml` no requiera cambios de código, solo rotación de
   valores.
5. Revisar también `FASTLANE_TEAM_ID` usado en
   [.github/workflows/prepare-release.yml:115-120](.github/workflows/prepare-release.yml#L115-L120)
   si aplica el mismo build de iOS ahí.

**Hasta que esto no esté hecho:** dejar constancia (este documento) de que los
builds de iOS/Android publicados por CI pueden estar firmados bajo la identidad
de Immich, y que no se debe asumir que el pipeline está desacoplado de Immich
solo porque el bundle ID ya cambió.
