# Instalar CleanMac y recibir actualizaciones

CleanMac es gratis y de código abierto. Funciona en macOS 13 Ventura o posterior,
tanto en Mac con Apple silicon como en Mac con Intel. No necesitas Xcode, una
cuenta de GitHub ni una cuenta Apple Developer para instalarla.

## 1. Descargar e instalar

1. Descarga [la última versión de CleanMac.dmg](https://github.com/chitorlando/cleanmac/releases/latest/download/CleanMac.dmg).
   También puedes encontrarla en las [publicaciones de GitHub](https://github.com/chitorlando/cleanmac/releases).
   El archivo de instalación es **CleanMac.dmg**; no necesitas descargar «Source code».
2. Abre el DMG con doble clic.
3. Arrastra **CleanMac** al acceso a **Aplicaciones** que aparece dentro del DMG.
4. Espera a que termine la copia y expulsa el volumen **CleanMac** desde Finder.
5. Abre la carpeta **Aplicaciones** e inicia CleanMac desde allí.

Una vez instalada, puedes borrar el archivo `.dmg` de Descargas. La copia que
usas está en Aplicaciones. No ejecutes la app directamente desde el DMG: ese
volumen es de solo lectura y Sparkle no puede reemplazar esa copia para actualizarla.

## 2. Autorizar la primera apertura

CleanMac se distribuye sin certificado Developer ID ni notarización de Apple.
Usa una firma local gratuita, por lo que macOS puede bloquear la primera apertura
con un aviso de que no puede verificar al desarrollador o comprobar la app.

Si has descargado el archivo del repositorio oficial enlazado arriba:

1. Intenta abrir **CleanMac desde Aplicaciones** y cierra el aviso si aparece.
2. Abre **Ajustes del Sistema → Privacidad y seguridad**.
3. Busca el aviso sobre CleanMac y pulsa **Abrir igualmente**.
4. Confirma la apertura y autentícate si macOS lo solicita.

No necesitas desactivar Gatekeeper ni ejecutar comandos en Terminal.

## 3. Permisos de la app

Puedes abrir CleanMac y revisar sus funciones antes de conceder permisos.
**Acceso total al disco** es opcional: permite analizar carpetas protegidas que,
sin ese permiso, se omiten. macOS también puede pedir acceso a carpetas o
autorización para que Finder mueva una app a la Papelera cuando uses esas funciones.

La lista y finalidad de cada permiso están en [Permisos de macOS](../README.md#permisos-de-macos).

## 4. Esperar avisos de actualizaciones

Sparkle, el actualizador integrado, puede pedirte a partir del segundo inicio
permiso para buscar versiones automáticamente. Acepta si quieres recibir avisos.

Con la búsqueda automática habilitada, CleanMac consulta las publicaciones
aproximadamente **una vez cada 24 horas mientras la app está en ejecución**.
Necesita conexión a internet. Si la app está cerrada, no mantiene un servicio
propio buscando versiones en segundo plano.

No tienes que revisar GitHub, descargar otro DMG ni borrar la app anterior.
El aviso no es inmediato al publicar una versión y no tiene por qué aparecer
en cada arranque. Si todavía no hay una versión más reciente, puedes seguir
usando CleanMac con normalidad.

## 5. Buscar e instalar una actualización ahora

1. Abre la copia de CleanMac instalada en **Aplicaciones**.
2. En la barra de menús de macOS, elige **CleanMac → Buscar actualizaciones…**.
   Si usas la app en inglés, la opción es **Check for Updates…**.
3. Si hay una versión nueva, revisa sus novedades en español o inglés.
4. Acepta descargar e instalar la actualización y espera a que termine.
5. Sparkle verifica la descarga, reemplaza la app y la reinicia. macOS puede
   pedir autorización si es necesaria para modificar la carpeta de instalación.

La instalación automática está **desactivada por defecto**; las preferencias que
elijas en los avisos de Sparkle pueden cambiar ese comportamiento. También puedes
buscar manualmente aunque no hayas aceptado la búsqueda automática.

Las actualizaciones usan una firma criptográfica Ed25519 gratuita para comprobar
su procedencia e integridad. Esa firma es independiente de los certificados de
Apple y no convierte la app en una aplicación notarizada.

## Si una actualización no aparece

| Situación | Qué hacer |
| --- | --- |
| No aparece ningún aviso | Abre CleanMac y usa **Buscar actualizaciones…** para comprobarlo sin esperar al siguiente ciclo. |
| La app indica que está al día | No hay una versión compatible más reciente anunciada en el canal de actualizaciones. |
| Hay un error de conexión | Comprueba internet y vuelve a intentarlo más tarde. Las funciones locales de CleanMac siguen disponibles. |
| La app está abierta desde el DMG | Ciérrala, cópiala a Aplicaciones, expulsa el DMG y abre la copia instalada. |
| No existe el menú de actualizaciones | Puede ser una copia anterior a Sparkle. Instala manualmente el DMG actual una vez. |
| macOS vuelve a pedir permisos después de actualizar | Revisa los permisos de CleanMac en Privacidad y seguridad; al usar firma ad hoc, puede ser necesario concederlos otra vez. |

Si usabas una versión anterior a Sparkle, cierra CleanMac y arrastra la nueva copia
del DMG a Aplicaciones, aceptando reemplazar la anterior cuando Finder lo pregunte.
Las siguientes versiones podrán instalarse desde el menú de actualizaciones.

Para compilar o publicar versiones del proyecto, consulta la
[guía para mantenedores](RELEASING.md).
