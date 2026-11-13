# CleanMac

[![CI](https://github.com/chitorlando/cleanmac/actions/workflows/ci.yml/badge.svg)](https://github.com/chitorlando/cleanmac/actions/workflows/ci.yml)

**Mantenimiento y limpieza para macOS. Libre, nativo y de código abierto.**

CleanMac es una alternativa gratuita a las suites comerciales de limpieza para Mac.
Está escrita en Swift y SwiftUI, con Sparkle para las actualizaciones, y su código es pequeño,
modular y fácil de auditar. No hay suscripciones, telemetría ni anuncios.

> Proyecto personal sin ánimo de lucro. No está afiliado a MacPaw ni a CleanMyMac.

---

## Funciones

| Estado | Función | Qué hace |
| :----: | ------- | -------- |
| ✅ | **Basura del sistema** | Encuentra cachés y registros de tu usuario y restos de Xcode (Derived Data, Device Support y cachés de los simuladores). Deja fuera las cachés de iCloud y de las cuentas, cuyo borrado podría forzar una resincronización o cerrar tu sesión. |
| ✅ | **Privacidad** | Borra las cachés de Safari, Chrome, Edge, Brave, Arc, Vivaldi, Opera y Firefox, agrupadas por navegador con su icono. Solo toca carpetas de caché conocidas: el historial, las cookies, las contraseñas, las sesiones y los marcadores nunca se listan. Las cachés de un navegador abierto quedan bloqueadas hasta que sales de él. |
| ✅ | **Desinstalador** | Lista las apps de `/Applications` y `~/Applications` con lo que ocupan y encuentra sus residuos en la Library de tu usuario: datos de soporte, cachés, preferencias, contenedores, estado guardado, registros, datos web, agentes de inicio y scripts. Permite buscar y ordenar por nombre o tamaño. También recibe las apps que el Mapa del disco encuentra en otras carpetas, como Descargas. |
| ✅ | **Archivos grandes y antiguos** | Recorre tu carpeta de inicio en busca de archivos de 50 MB o más y los filtra por tipo, tamaño, último uso y nombre. Puedes detener el análisis y revisar lo encontrado hasta entonces. También busca solo en una carpeta que elijas en el Mapa del disco, con las mismas exclusiones que el análisis completo. |
| ✅ | **Duplicados** | Busca en tu carpeta de inicio archivos idénticos de 1 MB o más: compara el tamaño, los primeros 64 KB y el SHA-256 completo. Muestra el espacio recuperable de cada grupo y sugiere qué copia conservar. También puede buscar solo en una carpeta que elijas en el Mapa del disco, con las mismas exclusiones que en toda la carpeta de inicio. |
| ✅ | **Mantenimiento** | Cinco tareas a elegir: vaciar la caché DNS, liberar memoria, reindexar Spotlight, reconstruir Launch Services y restablecer la caché de Quick Look. |
| ✅ | **Mapa del disco** | Dibuja en anillos lo que ocupa cada carpeta de tu carpeta de inicio, `~/Library` incluida, junto a una lista ordenada por tamaño. Puedes entrar en las carpetas, volver con las migas y mover a la Papelera lo que no necesites. Con clic derecho sobre un elemento de la lista puedes mostrarlo en Finder, copiar su ruta o pasarlo a otra función, como el Desinstalador si es una app. |
| ✅ | **Ítems de inicio** | Lista lo que arranca al iniciar sesión o funciona en segundo plano: los agentes de `~/Library/LaunchAgents` («Solo tú») y los agentes y daemons de `/Library` («Todos los usuarios»), con la app a la que pertenecen. Marca como huérfanos los que apuntan a un programa que ya no existe. Tus agentes se pueden mover a la Papelera; los de `/Library` solo se muestran en Finder. Abre también los ajustes de ítems de inicio de macOS. |
| ✅ | **Monitor** | Muestra en directo el uso de la CPU con su historial, la memoria y su presión, el espacio del disco de arranque y del de tu carpeta de inicio, y tus procesos que más CPU o memoria usan. Solo lee: no cierra ni cambia nada, y deja de medir cuando no está a la vista. |

## Seguridad primero

- **Todo va a la Papelera.** Nada se borra directamente, así que cualquier limpieza se puede deshacer.
  Las apps protegidas, como las de la App Store, se mueven a través de Finder con tu contraseña
  de administrador y conservan la opción «Devolver».
- **Siempre revisas antes de limpiar.** Ves cada elemento y puedes desmarcar lo que quieras.
  En Basura del sistema y Privacidad todo sale marcado, salvo las cachés de un navegador abierto; en el Desinstalador,
  Archivos grandes, Duplicados e Ítems de inicio no se marca nada hasta que lo eliges tú.
- **Apps abiertas y residuos compartidos.** No se puede desinstalar una app abierta: hay que cerrarla antes.
  Los residuos que comparten varias copias de una misma app nunca se marcan solos.
- **Mapa del disco con candado.** Dentro de `~/Library` solo se puede borrar el contenido de Caches y Logs;
  lo demás se abre en Finder. Llaveros, Mail, Mensajes, iCloud Drive y los contenedores de apps nunca se tocan,
  las fototecas y las carpetas estándar como Documentos no se borran enteras, y las apps se eliminan
  con el Desinstalador.
- **Privacidad solo con cachés.** Cada navegador tiene una lista de carpetas de caché permitidas: todo lo que
  no está en ella, como el historial, las cookies o las contraseñas, nunca aparece. Si el navegador está abierto,
  CleanMac te pide que salgas de él y nunca lo cierra a la fuerza.
- **Duplicados sin riesgo.** Siempre queda al menos una copia de cada grupo, y los clones de APFS,
  que comparten sus datos en el disco, cuentan como una sola copia física.
- **Fuera de los archivos del sistema.** CleanMac trabaja con tu carpeta de usuario y las apps instaladas,
  y nunca modifica `/Library` ni `/System`: Ítems de inicio solo lee los de `/Library`. Mantenimiento solo actúa
  cuando eliges y ejecutas sus tareas, y pide la contraseña de administrador una sola vez.
- **Ítems de inicio sin sorpresas.** CleanMac no habla con launchd: solo lee sus listas de propiedades.
  Un agente que mueves a la Papelera deja de ejecutarse en tu próximo inicio de sesión.
- **Red solo para actualizar.** Sparkle consulta GitHub para buscar versiones y descargar
  actualizaciones y sus notas. La limpieza y los análisis se realizan en tu Mac; no hay
  telemetría ni envío de los archivos analizados.

## Requisitos

- macOS 13 Ventura o posterior
- Xcode 26 o posterior (Swift 6.2) para compilar
- Xcode 27 o posterior (Swift 6.4) para `make strings`, igual que la CI

## Descargar e instalar

1. Descarga [CleanMac.dmg](https://github.com/chitorlando/cleanmac/releases/latest/download/CleanMac.dmg).
2. Abre el DMG y arrastra **CleanMac** al acceso a **Aplicaciones** que aparece dentro.
3. Expulsa el DMG y abre **CleanMac desde Aplicaciones**. Después puedes borrar el DMG.

La distribución es gratuita y no usa una cuenta de pago de Apple: la app está firmada
con un certificado propio, sin Developer ID ni notarización. Si macOS bloquea la
primera apertura, intenta abrirla y luego ve a **Ajustes del Sistema → Privacidad
y seguridad → Abrir igualmente**. No necesitas desactivar Gatekeeper. Como todas las
versiones usan el mismo certificado, los permisos que concedas se conservan al actualizar.

**[Guía de instalación y actualizaciones](docs/INSTALLING.md)**: instrucciones paso a
paso, permisos opcionales y qué hacer si macOS bloquea la apertura o no aparece una actualización.

## Recibir actualizaciones

- A partir de los primeros inicios, Sparkle te preguntará si quieres **buscar
  actualizaciones automáticamente**. Acepta para recibir avisos de nuevas versiones.
- Con esa opción habilitada, CleanMac busca aproximadamente **una vez al día mientras
  está abierta** y tienes conexión a internet. El aviso no tiene por qué aparecer en
  cuanto se publica una versión ni cada vez que abres la app.
- Para comprobarlo en cualquier momento, usa **CleanMac → Buscar actualizaciones…**
  en la barra de menús de macOS; en inglés, **Check for Updates…**.
- Cuando haya una versión nueva, revisa sus novedades y acepta la instalación.
  Sparkle descarga, verifica y reemplaza la app, y la reinicia. **No hace falta volver
  a descargar el DMG ni borrar la versión anterior.**

La instalación automática está desactivada por defecto. Las descargas se verifican
con una clave Ed25519 gratuita, independiente de los certificados de Apple.
Las copias anteriores a la integración de Sparkle necesitan una última instalación
manual; después podrán actualizarse desde la app.

## Instalación desde el código

```bash
git clone https://github.com/chitorlando/cleanmac.git
cd cleanmac
make app      # genera build/CleanMac.app
make install  # la copia a /Applications
```

Las compilaciones locales usan firma ad hoc, así que macOS puede pedir otra vez los
permisos a cada una. Las versiones publicadas se firman con el certificado del proyecto
(ver [docs/RELEASING.md](docs/RELEASING.md)).

## Permisos de macOS

macOS puede pedirte estos permisos. Todos se gestionan en Ajustes del Sistema > Privacidad y seguridad.

- **Acceso total al disco.** Opcional y recomendado: permite analizar carpetas protegidas.
  Sin él, la app simplemente las omite.
- **Automatización de Finder.** Al desinstalar una app protegida, CleanMac pide a Finder que la mueva
  a la Papelera, para que puedas recuperarla con «Devolver».
- **Escritorio, Documentos y Descargas.** En el primer análisis de Archivos grandes, Duplicados
  o Mapa del disco, que recorren tu carpeta de inicio.
- **Datos de otras apps.** Cuando el Desinstalador o el Mapa del disco miden los contenedores de otras apps
  en tu Library.
- **Contraseña de administrador.** En Mantenimiento, para las tareas que lo necesitan (DNS, memoria
  y Spotlight), una sola vez por ejecución.

## Desarrollo

```bash
open Package.swift   # abre el proyecto en Xcode
make run             # compila y lanza la app
make test            # ejecuta los tests
make dmg             # compila la app universal y genera build/CleanMac.dmg
make strings         # sincroniza los String Catalogs con el código
make clean           # borra los productos de compilación
./scripts/make-app-icon.sh  # regenera el icono de la app
```

Cada pull request se compila y se prueba en GitHub Actions ([`ci.yml`](.github/workflows/ci.yml)):
compilación limpia, tests, String Catalogs sincronizados (`make strings`) y empaquetado de la app
en versión universal, para Apple silicon e Intel (`./scripts/build-app.sh release arm64 x86_64`).

Cada ejecución publica esa app como artefacto `CleanMac-universal`, disponible durante 14 días,
así que puedes probarla en un Mac que no pueda compilar el proyecto:

```bash
rm -rf build                                         # por si ya había una app
gh run list --workflow ci.yml                        # busca la ejecución y copia su ID
gh run download <ID> -n CleanMac-universal -D build  # descarga build/CleanMac.app.zip
ditto -x -k build/CleanMac.app.zip build             # conserva los permisos y la firma
open build/CleanMac.app
```

### Publicaciones

Los tags estables `vMAJOR.MINOR.PATCH` activan el workflow `release.yml`: pruebas,
compilación universal, DMG, firma Ed25519 y GitHub Release con `appcast.xml`.
No usa certificados ni servicios de notarización de Apple.

Consulta [la guía de publicación](docs/RELEASING.md) para configurar la clave de
Sparkle, preparar las notas en ambos idiomas y publicar una versión.

### Arquitectura

El proyecto es un paquete de Swift dividido en módulos con una sola responsabilidad cada uno.

```
Sources/
├── CleanMacCore/         Lógica sin interfaz: recorrido de archivos, tamaños, selección, Papelera y procesos
├── CleanMacUI/           Sistema de diseño, componentes comunes y contrato de las funciones
├── SystemJunkFeature/    Basura del sistema
├── PrivacyFeature/       Privacidad
├── UninstallerFeature/   Desinstalador
├── LargeFilesFeature/    Archivos grandes y antiguos
├── DuplicatesFeature/    Duplicados
├── DiskMapFeature/      Mapa del disco
├── MaintenanceFeature/   Mantenimiento
├── LoginItemsFeature/    Ítems de inicio
├── MonitorFeature/       Monitor
└── CleanMacApp/          Punto de entrada, barra lateral y composición de dependencias
```

Cada función es un módulo con su dominio, su presentación y su interfaz, y depende solo de
`CleanMacCore` y `CleanMacUI`:

- **`FeatureModule`** es el contrato que implementa cada función: identificador, título, icono, tema,
  sección y la vista que muestra.
- **`FeatureSection`** agrupa las funciones en la barra lateral: Limpieza, Aplicaciones, Archivos y Rendimiento.
- **`AppComposition`** es el único sitio que conoce todas las funciones y crea sus dependencias reales.

Para añadir una función, crea su target en `Package.swift` (con sus tests), implementa `FeatureModule`
con un constructor `live()` y regístralo en `AppComposition.makeModules()`. Si estaba anunciada,
quítala de `UpcomingFeature.roadmap`. Las demás funciones no cambian.

### Principios del código

- **SOLID.** Las dependencias se inyectan mediante protocolos pequeños, lo que permite probarlas con dobles.
- **Componentes pequeños.** Una vista o un tipo por archivo, con una sola responsabilidad.
- **Concurrencia segura.** Swift 6 en modo estricto. El trabajo pesado nunca bloquea la interfaz.
- **Dependencias acotadas.** Frameworks de Apple y Sparkle para las actualizaciones;
  su distribución binaria oficial está fijada por versión y checksum en `Package.swift`.

## Idiomas

CleanMac está disponible en **inglés** y **español**. La app sigue el idioma de macOS
y, si prefieres usarla en un idioma distinto al del sistema, puedes elegirlo solo para ella en
Ajustes del Sistema > General > Idioma y región > Aplicaciones.

### Añadir y traducir textos

El inglés es el idioma base: los textos se escriben en inglés en el código y cada módulo
guarda sus traducciones en un String Catalog, `Sources/<Módulo>/Resources/Localizable.xcstrings`.

1. Escribe el texto en inglés indicando el bundle del módulo y un comentario para quien traduzca:
   - En las vistas: `Text("Scan", bundle: .module, comment: "…")`. `Button`, `Section` y `Label`
     se escriben con su variante de etiqueta personalizada para poder pasar `bundle: .module`.
   - Fuera de las vistas: `String(localized: "Scan", bundle: .module, comment: "…")`.
2. Ejecuta `make strings`. Compila el proyecto, añade las claves nuevas al catálogo de cada módulo
   y marca como `stale` las que ya no se usan.
3. Abre el catálogo en Xcode, o edita su JSON, y escribe la traducción `es` de cada clave nueva.
   Si el texto lleva un número, usa variaciones plurales (`one` y `other`) en inglés y en español.
4. Ejecuta `make strings` otra vez y borra las claves `stale` que queden.

`make test` incluye una comprobación de cobertura (`LocalizationTests`): falla si alguna clave
no tiene traducción al español, si queda alguna clave `stale` o si el español usa plurales
y el inglés no.

## Contribuir

Las contribuciones son bienvenidas. Abre un issue para comentar la idea antes de un pull request grande.

- `main` está protegida: todo entra por pull request, la CI «Build and test» debe pasar
  y la rama debe estar al día con `main`.
- Haz commits pequeños, uno por cambio, con mensajes en inglés, y añade tests para la lógica nueva.
- Escribe los textos en inglés y en español, y sincroniza los catálogos con `make strings`.

## Licencia

Distribuido bajo la [licencia MIT](LICENSE).
