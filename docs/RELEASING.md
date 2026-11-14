# Publicar CleanMac sin cuenta de pago de Apple

La app se distribuye firmada con un certificado autofirmado gratuito, sin cuenta
de pago de Apple, Developer ID ni notarización. El DMG contiene `CleanMac.app` y un
enlace a `/Applications`. Como no está notarizada, macOS sigue bloqueando la primera
apertura hasta que se pulsa «Abrir igualmente»: las instrucciones están en
`releases/INSTALL.md`.

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

SwiftPM nombra esa carpeta como la de tu copia del repositorio: `cleanmac` en un
clon normal, otro nombre en un worktree. Los scripts la encuentran solos con
`scripts/lib/sparkle.sh`; en los comandos de abajo, cámbiala si tu copia se llama
de otra forma.

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

## Certificado de firma (una sola vez)

macOS recuerda los permisos de una app, como Acceso total al disco o el control
de Finder, por su *requisito designado*. Con firma ad hoc ese requisito es el hash
del propio ejecutable (`cdhash H"…"`), distinto en cada compilación, así que cada
actualización de Sparkle es una app nueva para macOS y los permisos se pierden.
Firmada con un certificado, el requisito pasa a ser el identificador de la app y el
hash del certificado:

```text
identifier "io.github.cleanmac" and certificate leaf = H"…"
```

Ese requisito es el mismo en todas las versiones firmadas con el mismo certificado,
así que los permisos se conservan al actualizar. No hace falta Developer ID: un
certificado autofirmado basta, aunque no evita el paso de «Abrir igualmente».

Para crearlo, ejecuta una sola vez y guarda los archivos fuera del repositorio:

```bash
./scripts/create-signing-certificate.sh ~/Desktop/CleanMac-signing.p12
base64 -i ~/Desktop/CleanMac-signing.p12 | gh secret set CODESIGN_P12_BASE64 --repo chitorlando/cleanmac
gh secret set CODESIGN_P12_PASSWORD --repo chitorlando/cleanmac < ~/Desktop/CleanMac-signing.p12.password
```

El script usa OpenSSL, no modifica el Llavero y nunca imprime la clave ni la
contraseña. Crea «CleanMac Self-Signed», válido 20 años, como `.p12` protegido por
una contraseña aleatoria que guarda junto a él (`.p12.password`, permisos 600).

Guarda **los dos archivos** en una copia de seguridad sin conexión, por ejemplo en
un disco cifrado, y bórralos después del Escritorio. No vuelvas a ejecutar el script
para «renovar» el certificado: uno nuevo cambia la identidad de la app y los usuarios
tendrían que conceder los permisos otra vez. Si se pierde, la siguiente versión se
firma con uno nuevo y ocurre lo mismo, una sola vez.

El workflow importa el certificado en un llavero temporal, firma la app con él,
muestra el requisito designado en el registro, comprueba que es el estable y borra
el llavero. Si falta `CODESIGN_P12_BASE64`, publica con firma ad hoc y deja un
aviso en la ejecución: esa versión vuelve a pedir los permisos.

Para ensayar la firma sin secretos:

```bash
make signing-dry-run
```

Crea un certificado desechable en un llavero temporal, compila `build/CleanMac.app`
firmada con él, la comprueba y borra el certificado y el llavero.

### Compatibilidad con Sparkle

Sparkle 2.10.1 acepta el cambio de firma, según su código fuente
(`SUUpdateValidator.m` y `SUCodeSigningVerifier.m`):

- CleanMac tiene `SUVerifyUpdateBeforeExtraction`, así que Sparkle valida primero
  la firma EdDSA del DMG con la clave pública de la app instalada. Después de
  extraerlo solo exige que la app nueva tenga una firma de código válida. No compara
  su identidad con la anterior, de modo que pasar de la 0.1.0, ad hoc, a una versión
  autofirmada funciona mientras la clave EdDSA no cambie.
- Sin esa opción, Sparkle acepta la actualización si es válida la firma EdDSA **o**
  la firma de código coincide con el requisito designado de la app instalada. Entre
  versiones autofirmadas se cumplen las dos.
- Sparkle restringe la conexión con sus servicios XPC al Team ID de la app, y un
  certificado autofirmado no tiene Team ID, así que no se aplica ninguna restricción.
- La firma de Sparkle.framework y sus servicios se conserva tal como viene en el
  paquete de Swift Package Manager: ad hoc. La app no activa el *hardened runtime*,
  así que no hay validación de bibliotecas que exija la misma identidad.

Por eso **no se pueden cambiar a la vez la clave EdDSA y el certificado**: una de
las dos firmas debe seguir siendo la de la versión instalada.

### Con un Developer ID

Si algún día hay cuenta de Apple Developer, la firma con Developer ID y la
notarización eliminarán el paso de «Abrir igualmente». Pasar del certificado
autofirmado al Developer ID funciona igual que el paso desde ad hoc: Sparkle lo
acepta por la firma EdDSA, pero el requisito designado cambia y los usuarios
concederán los permisos una última vez.

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
Prueba los permisos de Finder y Acceso total al disco después de actualizar entre
dos versiones firmadas con el certificado: deben conservarse. En el registro de la
publicación, «Designated requirement» debe mostrar el mismo hash en todas.

Sparkle pregunta al usuario si desea buscar versiones automáticamente y no activa
la instalación automática por defecto. No envía perfiles del sistema. Usa
`make run` para probar el actualizador: los ejecutables sueltos de `swift run` y
los tests no inician un ciclo de actualizaciones.
