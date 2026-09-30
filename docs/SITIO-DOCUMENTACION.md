# Sitio de documentación (Docusaurus)

Esta carpeta es el **sitio web de documentación** de Great Memories, hecho con [Docusaurus](https://docusaurus.io/). Es la versión heredada de `docs.immich.app`.

- El contenido está en [docs/](docs/) (Markdown/MDX), por ejemplo [docs/developer/setup.md](docs/developer/setup.md).
- La navegación lateral está en [sidebars.js](sidebars.js) y la configuración general en [docusaurus.config.js](docusaurus.config.js).
- Las guías internas del equipo (servidor, entorno local, APK, iOS) **no** están aquí, sino en la raíz del repo: `CONFIGURACION-SERVIDOR.md`, `DESARROLLO-LOCAL.md`, `GENERAR-APK.md`, `GENERAR-IOS.md`.

## Verlo en local

Requiere Node 24 y pnpm (los instala `mise install` desde la raíz; ver [DESARROLLO-LOCAL.md](../DESARROLLO-LOCAL.md)). Desde la raíz del repo:

```bash
mise //docs:install
mise //docs:start
```

Abrir <http://localhost:3005>. Los cambios en los `.md` se ven al guardar, sin reiniciar.

Sin mise, desde `docs/`: `pnpm install` y luego `pnpm run start`.

## Compilar

```bash
mise //docs:build     # genera el sitio estático en docs/build/
mise //docs:preview   # sirve docs/build/ para revisarlo
```

## Publicación: pendiente

El sitio **todavía no tiene publicación propia**. Los workflows [docs-build.yml](../.github/workflows/docs-build.yml) y [docs-deploy.yml](../.github/workflows/docs-deploy.yml) lo suben a Cloudflare Pages con infraestructura de Immich, y `url` en `docusaurus.config.js` sigue siendo `https://docs.immich.app`. Falta un dominio propio: ver punto 5 de [REBRANDING_TODO.md](../REBRANDING_TODO.md).
