# Publicar CleanMac sin cuenta de pago de Apple

La app se distribuye con firma ad hoc gratuita, sin Developer ID ni notarización.
El DMG contiene `CleanMac.app` y un enlace a `/Applications`. macOS puede bloquear
la primera apertura: las instrucciones están en `releases/INSTALL.md`.

Sparkle es la única dependencia externa. La firma Ed25519 de las actualizaciones
es gratuita e independiente de Apple. No se debe quitar: permite que una app
instalada compruebe que la actualización procede del proyecto.

## Clave de actualizaciones (una sola vez)

La clave pública está en `Support/Info.plist`, en `SUPublicEDKey`. La privada se
guarda en el Llavero de macOS, con la cuenta `io.github.cleanmac`, y en el secreto
`SPARKLE_PRIVATE_KEY` del repositorio `chitorlando/cleanmac`.

Después de `swift package resolve`, las herramientas oficiales están en:

```text
.build/artifacts/cleanmac/Sparkle/bin/
```

Para consultar la clave pública existente:

```bash
.build/artifacts/cleanmac/Sparkle/bin/generate_keys --account io.github.cleanmac -p
```

Para configurar el secreto de GitHub desde el Llavero, con `gh` autenticado:

```bash
./scripts/configure-sparkle-secret.sh
```

El script comprueba que la clave coincide con la pública de la app, exporta la
privada a un directorio temporal con permisos restringidos, la envía a GitHub
por entrada estándar y elimina el archivo temporal. Nunca la imprime.

Haz una copia de seguridad de la clave privada en un lugar seguro fuera del
repositorio usando `generate_keys --account io.github.cleanmac -x /ruta/segura`.
No guardes esa exportación en Git, en artefactos de CI ni en una Release.
Sin certificado Developer ID, perder esta clave puede obligar a los usuarios a
instalar manualmente una nueva versión para restablecer las actualizaciones.

## Publicar una versión

1. Añade `releases/vX.Y.Z.en.html` y `releases/vX.Y.Z.es.html` con sus novedades.
2. Integra los cambios en `main` y comprueba que la CI pasa.
3. Crea y sube el tag sobre ese commit:

```bash
git tag -a v0.1.0 -m "CleanMac 0.1.0"
git push origin v0.1.0
```

Usa una versión nueva para cada publicación. Solo se aceptan tags estables
`vMAJOR.MINOR.PATCH`; este canal no publica betas. No muevas tags publicados.

El workflow `release.yml` usa el mismo runner `xcode-27` y Xcode 27.2 que la CI.
Antes de compilar establece `CFBundleShortVersionString` a partir del tag y
`CFBundleVersion` a `github.run_number + 1000`. Ambos valores se aplican al plist
fuente para mantener coherentes el ejecutable y el bundle. Conserva este contador
creciente si sustituyes el workflow o migras las publicaciones a otro repositorio.

Después ejecuta los tests, compila para `arm64` y `x86_64`, verifica las firmas
locales y crea el DMG. Sparkle firma el archivo final y genera `appcast.xml` con
notas en español e inglés. Una comprobación con CryptoKit valida la firma contra
la clave pública de la app antes de subir los archivos.

La Release se crea como borrador y solo se publica después de subir todos los
archivos. Si una ejecución falla dejando un borrador, revisa y elimina ese
borrador antes de reintentar; el workflow no sobrescribe publicaciones existentes.
Publica siempre las versiones en orden creciente.

## URLs públicas

- Descarga: `https://github.com/chitorlando/cleanmac/releases/latest/download/CleanMac.dmg`
- Feed: `https://github.com/chitorlando/cleanmac/releases/latest/download/appcast.xml`

No hace falta habilitar GitHub Pages ni mantener un servidor. El feed de cada
Release contiene la versión actual y apunta a su DMG con una URL específica del
tag. El enlace `latest` sirve para descubrir versiones; los enlaces de descarga
dentro del feed nunca usan `latest`, para no mezclar archivos con firmas antiguas.
Si una versión futura cambia los requisitos de macOS o arquitecturas, habrá que
conservar también entradas anteriores compatibles en el feed.

## Generar y comprobar localmente

```bash
make dmg
```

Genera `build/CleanMac.dmg` universal sin certificado de Apple. Para volver a
empaquetar una app ya compilada: `./scripts/build-dmg.sh`.

Para ensayar la publicación con la clave del Llavero:

```bash
./scripts/build-appcast.sh v0.1.0
```

El tag debe coincidir con la versión de `build/CleanMac.app`. El resultado va a
`build/release/`; mueve esa carpeta aparte antes de repetir el comando. No se
publica nada automáticamente al ejecutar estos scripts locales.

Comprueba la instalación desde el DMG en otro Mac, la apertura inicial, el menú
«Buscar actualizaciones…» y, entre dos versiones, la sustitución y el reinicio.
Prueba los permisos de Finder y Acceso total al disco después de actualizar:
sin una identidad Developer ID estable, macOS puede solicitar autorización otra vez.

Sparkle pregunta al usuario si desea buscar versiones automáticamente y no activa
la instalación automática por defecto. No envía perfiles del sistema. Usa
`make run` para probar el actualizador: los ejecutables sueltos de `swift run` y
los tests no inician un ciclo de actualizaciones.
