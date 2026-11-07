# CleanMac

**Mantenimiento y limpieza para macOS. Libre, nativo y de código abierto.**

CleanMac es una alternativa gratuita a las suites comerciales de limpieza para Mac.
Está escrita en Swift y SwiftUI, sin dependencias externas, y su código es pequeño,
modular y fácil de auditar. No hay suscripciones, telemetría ni anuncios.

> Proyecto personal sin ánimo de lucro. No está afiliado a MacPaw ni a CleanMyMac.

---

## Funciones

| Estado | Función | Qué hace |
| :----: | ------- | -------- |
| ✅ | **Basura del sistema** | Detecta cachés, registros y restos de desarrollo (Xcode, simuladores) y los mueve a la Papelera. |
| 🚧 | **Desinstalador** | Elimina una app junto con sus preferencias, cachés y datos de soporte. |
| 🚧 | **Archivos grandes y antiguos** | Encuentra lo que más ocupa y lo que no abres desde hace tiempo. |
| 🚧 | **Mapa del disco** | Visualiza el espacio ocupado por carpetas. |
| 🚧 | **Duplicados** | Localiza archivos idénticos comparando tamaño y contenido. |
| 🚧 | **Privacidad** | Limpia cachés e historial de los navegadores. |
| 🚧 | **Ítems de inicio** | Gestiona apps y agentes que arrancan con el sistema. |
| 🚧 | **Mantenimiento** | Vacía la caché DNS, reindexa Spotlight y libera memoria. |
| 🚧 | **Monitor** | CPU, memoria y disco desde la barra de menú. |

## Seguridad primero

- **Nada se borra directamente.** Todo se mueve a la Papelera, así que cualquier limpieza se puede deshacer.
- **Revisión antes de limpiar.** Siempre ves qué se va a eliminar y puedes desmarcar lo que quieras.
- **Fuera de los archivos del sistema.** CleanMac solo trabaja dentro de tu carpeta de usuario y nunca toca rutas protegidas por macOS.
- **Sin red.** La app no se conecta a internet.

## Requisitos

- macOS 15 Sequoia o posterior
- Xcode 16 o posterior (Swift 6) para compilar

## Instalación desde el código

```bash
git clone https://github.com/chitorlando/cleanmac.git
cd cleanmac
make app      # genera build/CleanMac.app
make install  # la copia a /Applications
```

La primera vez, macOS puede avisar de que la app no está verificada.
Ábrela con clic derecho y "Abrir", o desde Ajustes del Sistema > Privacidad y seguridad.

Para analizar algunas carpetas protegidas, concede a CleanMac
**Acceso total al disco** en Ajustes del Sistema > Privacidad y seguridad.
Es opcional: sin ese permiso la app simplemente omite esas carpetas.

## Desarrollo

```bash
open Package.swift   # abre el proyecto en Xcode
make run             # compila y lanza la app
make test            # ejecuta los tests
./scripts/make-app-icon.sh  # regenera el icono de la app
```

### Arquitectura

El proyecto es un paquete de Swift dividido en módulos con una sola responsabilidad cada uno.

```
Sources/
├── CleanMacCore/        Lógica sin interfaz: sistema de archivos, tamaños, selección y limpieza
├── CleanMacUI/          Sistema de diseño y contrato común de las funciones
├── SystemJunkFeature/   Función "Basura del sistema" (dominio + interfaz)
└── CleanMacApp/         Punto de entrada y composición de dependencias
```

Cada función nueva es un módulo independiente que implementa `FeatureModule`
y se registra en un único sitio, `AppComposition`. Añadir una función no obliga a modificar las demás.

### Principios del código

- **SOLID.** Las dependencias se inyectan mediante protocolos pequeños, lo que permite probarlas con dobles.
- **Componentes pequeños.** Una vista o un tipo por archivo, con una sola responsabilidad.
- **Concurrencia segura.** Swift 6 en modo estricto. El trabajo pesado nunca bloquea la interfaz.
- **Sin dependencias externas.** Solo frameworks de Apple.

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

Las contribuciones son bienvenidas. Abre un issue para comentar la idea antes de un pull request grande,
mantén los cambios pequeños y añade tests para la lógica nueva.

## Licencia

Distribuido bajo la [licencia MIT](LICENSE).
