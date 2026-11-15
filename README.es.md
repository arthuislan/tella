<p align="center">
  <img src="docs/images/icon.png" alt="Ícono de Tella" width="128">
</p>

<h1 align="center">Tella</h1>

<p align="center">
  <b>El teclado sigue a tu cursor entre tu MacBook y tus monitores externos, sin hacer clic.</b>
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.pt-BR.md">Português</a> · <b>Español</b>
</p>

<p align="center">
  <a href="https://github.com/arthuislan/tella/releases/download/v1.4/Tella-1.4.dmg"><b>⬇︎ Descargar Tella 1.4</b></a>
  &nbsp;·&nbsp; macOS 13+ · Apple Silicon e Intel
</p>

<p align="center">
  <img src="docs/images/cover.png" alt="Tella — el teclado sigue a tu cursor entre la MacBook y la pantalla extra" width="100%">
</p>

**Tella** es una pequeña app para Mac, pensada para quienes trabajan con una **MacBook y uno o más monitores externos**. Cuando llevas el cursor a otra pantalla, Tella activa automáticamente la ventana que está al frente en esa pantalla. Así puedes escribir en ella de inmediato, **sin hacer clic**.

Vive discretamente en la barra de menús: no abre ventanas, no mueve nada de lugar y no hace clic en nada.

---

## El problema

En macOS, el teclado siempre escribe en la **app activa**, y una app solo se activa cuando haces clic en ella. Mover el cursor no basta. Con más de una pantalla, esto causa dos molestias del día a día.

### 1. El teclado se queda en la otra pantalla

Estás en el navegador del monitor externo, llevas el cursor a la MacBook y empiezas a escribir una nota. El texto termina en la barra de direcciones del navegador, en la otra pantalla.

![Sin Tella: el texto va a la ventana de la otra pantalla](docs/images/1-without-tella-keyboard.png)

### 2. Hacer clic para activar puede estorbar

La solución sería hacer clic en la otra pantalla antes de escribir. El problema es que el cursor muchas veces cae sobre una **ventana de atrás**, más grande, detrás de la ventana pequeña que estás usando. El clic cae en ella, salta al frente y **tapa la ventana que querías usar**.

![Sin Tella: el clic trae al frente la ventana de atrás](docs/images/2-without-tella-click.png)

---

## La solución

Con Tella encendido, el teclado sigue al cursor. Una ventana que **nada cubre** — flotando encima o lado a lado — se activa en cuanto el cursor entra en ella, en cualquier pantalla y en cualquier escritorio.

- ✅ El teclado sigue al cursor: solo apunta y escribe.
- ✅ No se simula ningún clic, así que ningún botón o enlace se activa por accidente.
- ✅ Ninguna ventana cambia de lugar, y la de atrás se queda atrás.

![Con Tella: la ventana se activa cuando el cursor entra, sin clic](docs/images/3-with-tella-activate.png)

Cuando el cursor sale a un espacio vacío (el escritorio o una ventana de atrás), el teclado queda **libre**: ninguna ventana queda activa, así que nada de lo que escribes va al lugar equivocado.

![Con Tella: al salir a un espacio vacío, el teclado queda libre](docs/images/4-with-tella-release.png)

---

## Cómo funciona

### Al llegar desde otra pantalla

1. Cuando el cursor **cambia de pantalla**, Tella espera a que llegue a una ventana, para nunca elegir una ventana antes de que llegues a ella.
2. Si el cursor entra en una ventana que **nada tapa**, esa ventana queda activa.
3. En cualquier otro lugar (barra de menús, escritorio o una ventana parcialmente detrás de otra), nada cambia: una ventana solo queda activa cuando el cursor la elige.

### Ventanas bajo el cursor

Con **Activar ventana bajo el cursor** activado (por defecto), toda ventana que **nada tapa** — flotando sobre las demás o lado a lado, como el Finder a la izquierda y la Terminal a la derecha — queda activa en cuanto el cursor entra en ella. Sin clic, en la MacBook, en el monitor externo y en todos los escritorios (Spaces).

Cuando el cursor **sale** de esa ventana hacia un espacio vacío — el escritorio, o una ventana de atrás, como el espacio entre el Finder y la Terminal — la ventana se **suelta**: ninguna ventana queda activa hasta que el cursor elija otra, así que nada de lo que escribas va al lugar equivocado. La barra de menús, los menús y el Dock no cuentan, así que sigues alcanzando los menús de la app activa.

Una ventana **parcialmente detrás de otra** nunca se activa con el cursor: activarla la traería al frente y taparía la ventana de adelante. En esos casos, haces clic, como siempre. Ninguna ventana cambia de lugar ni de orden.

Desactiva **Activar ventana bajo el cursor** para tener el comportamiento clásico: Tella solo actúa cuando el cursor cambia de pantalla, activando siempre la ventana del frente de esa pantalla.

### Al minimizar una ventana

Si minimizas la ventana que estabas usando, Tella activa **al instante** la ventana que quedó al frente en esa pantalla, normalmente la que estaba detrás. Así sigues escribiendo sin tener que hacer clic.

### Cuidados que toma la app

- **¿Arrastrando algo?** Con el botón del mouse presionado, Tella no hace nada, para no interrumpir el arrastre.
- **Spotlight, Raycast, Alfred y paneles similares:** mientras uno está abierto, Tella no cambia de ventana, para no cerrarlo.
- **Menús, Dock y avisos bajo el cursor:** Tella los ignora.
- **¿Conectaste o desconectaste un monitor?** Tella solo actualiza su referencia y no activa nada.
- **Ahorra batería:** Tella solo trabaja mientras el mouse se mueve.

Todo mediante la API de Accesibilidad de macOS.

---

## Menú de la barra de menús

| Opción | Qué hace |
|---|---|
| **Acerca de Tella** | Muestra la versión, el desarrollador, el sitio web y la licencia. |
| **Actualización disponible: Tella x.y** | Solo aparece cuando hay una versión nueva. Haz clic para descargarla. |
| **Activo** | Enciende o apaga Tella sin cerrar la app. |
| **Activar ventana bajo el cursor** | Las ventanas que nada tapa quedan activas cuando el cursor entra en ellas (activado por defecto). Desactivado = comportamiento clásico. |
| **Abrir al iniciar sesión** | Abre Tella automáticamente al iniciar sesión en tu Mac. |
| **Permiso** | Muestra si la Accesibilidad está permitida (✓) o falta (⚠︎) y agrupa las opciones de abajo. |
| ↳ **Abrir ajustes de Accesibilidad…** | Abre la lista de Accesibilidad en Ajustes del Sistema. |
| ↳ **Volver a pedir permiso** | Muestra de nuevo el aviso de macOS y agrega Tella a la lista. |
| ↳ **Restablecer permiso** | Borra el permiso anterior y lo pide de nuevo. Útil después de actualizar la app. |
| ↳ **Mostrar Tella en el Finder** | Muestra la app en el Finder para que la arrastres a la lista si no aparece. |
| **Buscar actualizaciones…** | Revisa ahora en GitHub si hay una versión nueva. |
| **Buscar actualizaciones automáticamente** | Revisa una vez al día (activado por defecto). Desactívalo si prefieres. |
| **Salir de Tella** | Cierra la app. |

---

## Idiomas

Tella usa automáticamente el idioma de tu Mac. Habla **36 idiomas**:

Português (Brasil) · Português (Portugal) · English · Español · Français · Deutsch · Italiano · Nederlands · Svenska · Dansk · Norsk · Suomi · Polski · Čeština · Slovenčina · Magyar · Română · Hrvatski · Slovenščina · Български · Català · Ελληνικά · Türkçe · Русский · Українська · עברית · العربية · हिन्दी · ไทย · Tiếng Việt · Bahasa Indonesia · Bahasa Melayu · 日本語 · 한국어 · 简体中文 · 繁體中文

Si el idioma de tu Mac no está en la lista, Tella aparece en **inglés**.

Para usar Tella en otro idioma sin cambiar todo tu Mac, ve a **Ajustes del Sistema → General → Idioma y región → Aplicaciones**, haz clic en **+** y elige Tella.

---

## Requisitos

- macOS 13 (Ventura) o posterior
- Mac con Apple Silicon (M1, M2, M3, M4…) o Intel
- Permiso de **Accesibilidad**, que Tella necesita para activar ventanas de otras apps

![Una app, dos procesadores: Apple Silicon e Intel](docs/images/5-universal.png)

---

## Instalación

### Con el instalador (DMG)

1. Descarga **[Tella-1.4.dmg](https://github.com/arthuislan/tella/releases/download/v1.4/Tella-1.4.dmg)** desde la página de [Releases](https://github.com/arthuislan/tella/releases).
2. Abre el DMG y arrastra **Tella** a la carpeta **Aplicaciones**.
3. Abre Tella. Como la app no está notarizada por Apple, la primera vez macOS puede avisar que no puede verificar al desarrollador. Para abrirla de todos modos, ve a **Ajustes del Sistema → Privacidad y seguridad → Abrir de todos modos**, o haz clic derecho en la app y elige **Abrir**.
4. Cuando Tella lo pida, activa el permiso en **Ajustes del Sistema → Privacidad y seguridad → Accesibilidad**.

### Compilar desde el código

Necesitas las herramientas de línea de comandos de Xcode (`xcode-select --install`).

```bash
git clone https://github.com/arthuislan/tella.git
cd tella
./build.sh --install   # compila, instala en /Applications y abre
./build.sh --dmg       # compila y crea el instalador Tella-x.y.dmg
```

`build.sh` genera una app universal (Apple Silicon + Intel). Si tu llavero tiene un certificado de firma de código (o defines `TELLA_SIGN_ID`), firma con él y macOS mantiene el permiso de Accesibilidad en cada compilación. Sin certificado, quizá debas volver a permitir Tella después de cada compilación.

---

## Solución de problemas

**Tella no activa las ventanas.**
Casi siempre es el permiso de Accesibilidad. Después de una actualización, macOS puede tratar a Tella como otra app.

La forma más fácil de arreglarlo es desde el propio Tella: en el menú, elige **Permiso → Restablecer permiso** y vuelve a activar Tella en la lista de Accesibilidad.

O, desde la Terminal:

```bash
pkill -x Tella
tccutil reset Accessibility local.tella
open /Applications/Tella.app
```

Luego vuelve a activar Tella en **Accesibilidad**.

**Sigue apareciendo el ícono anterior.**
Es la caché de macOS. Para actualizarla:

```bash
touch /Applications/Tella.app && killall Dock Finder
```

**¿Cómo desinstalo?**

```bash
pkill -x Tella
rm -rf /Applications/Tella.app
tccutil reset Accessibility local.tella
```

---

## Actualizaciones

Tella revisa una vez al día la página de [Releases](https://github.com/arthuislan/tella/releases). Cuando sale una versión nueva, te avisa y muestra **Actualización disponible** en el menú.

Para actualizar: descarga el nuevo **Tella-x.y.dmg**, ábrelo y arrastra Tella a **Aplicaciones**, reemplazando el anterior. Después de actualizar, macOS puede pedir de nuevo el permiso de **Accesibilidad**. Si no funciona de inmediato, usa **Permiso → Restablecer permiso** en el menú.

---

## Privacidad

Tella **no lee lo que escribes** y no graba nada. Solo observa la posición del cursor y la lista de ventanas abiertas para saber qué ventana activar.

La única vez que se conecta a internet es para revisar, como máximo una vez al día, la página pública de versiones de Tella en GitHub. No se envía nada sobre ti ni sobre tu Mac. Puedes desactivarlo en **Buscar actualizaciones automáticamente**.

---

## Estructura del proyecto

```
tella/
├── Sources/               # la app: WindowFocus.swift (qué ventana recibe el teclado),
│                          #   AppDelegate.swift (menú), Updates.swift, About.swift, Support.swift
├── Resources/
│   ├── AppIcon.iconset/    # ícono de la app
│   └── *.lproj/            # traducciones (36 idiomas)
├── Info.plist
├── build.sh                # compilar, instalar y crear el DMG
├── RELEASING.md            # cómo publicar una versión nueva
└── docs/
    ├── images/             # imágenes de este README
    └── src/gen.py          # script que genera las ilustraciones
```

El historial de versiones está en [CHANGELOG.md](CHANGELOG.md).

---

## Licencia

[MIT](LICENSE) © 2026 Arthuislan
