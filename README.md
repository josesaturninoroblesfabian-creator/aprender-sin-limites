# Aprende sin Límites

Juego educativo en Godot para explorar letras, practicar su trazado, descubrir cuentos, comprender números y aprender las cuatro operaciones, con personajes y ambientación andina. Su público previsto es inicial y primaria; incluye cuatro actividades de comprensión para los mismos 16 cuentos y ocho actividades internas tanto en Matemáticas como en Números.

## Ejecutar

1. Importar `project.godot` en Godot. La limpieza se verificó con **Godot 4.7.2**, usando el renderizador Compatibility.
2. Esperar la importación de imágenes, audio y modelo 3D.
3. Pulsar **F5** para ejecutar el proyecto completo. F6 ejecuta solo la escena abierta.

Se conserva el estilo ilustrado original: fondos, botones y personajes por imágenes. Incluye **300 audios locales en español** (270 palabras, 27 letras y tres instrucciones); no necesita una voz española instalada para reproducirlos. No hay reconocimiento de voz ni una IA integrada actualmente.

Los menús de **Matemáticas, Números y Geometría** comparten una llama animada y 33 audios neuronales locales, con ayuda y control de sonido. Se abren desde sus botones del inicio. Geometría conserva las presentaciones de sus temas. Detalles en [Menús matemáticos](docs/MENUS_MATEMATICOS.md).

**Matemáticas** ya permite jugar en sus ocho tarjetas: suma, resta, multiplicación, división, conteo, ejercicios, aventura por niveles y reto con globos. Incluye 16 misiones con ejemplos interactivos y 96 problemas narrados, doce caminos con plataformas y saltos, 155 audios locales adicionales y guardado para continuar. Todo funciona dentro de Godot sin conexión. Capturas, controles y guía para el equipo en [Actividades de Matemáticas](docs/MATEMATICAS_ACTIVIDADES.md).

**Números** también tiene sus ocho actividades internas: una a cuatro cifras con 20 misiones y 100 retos; mercado para contar, puentes de secuencias, comparación con balanza y tren de retos. Incluye piezas de valor posicional, arrastre, canjes, 207 audios locales nuevos y guardado de misiones parciales. Funciona dentro de Godot sin navegador ni internet. Ver [Actividades de Números](docs/NUMEROS_ACTIVIDADES.md).

**Cuentos** incluye a Carmelo animado con voz masculina peruana, 128 escenas ilustradas y 205 audios incluidos. Sus cuatro modos funcionan con los mismos 16 títulos: leer en viñetas, escuchar con palabras resaltadas, ordenar sucesos y responder preguntas con pistas y puntuación. Detalles, capturas y guía de edición en [Cuentos y Carmelo](docs/CUENTOS_Y_CARMELO.md).

## Estado real

| Área | Implementado |
| --- | --- |
| Inicio | Menú, saludos grabados, animaciones y despedida |
| Lenguaje | 27 letras, 10 ejemplos por letra, audio incluido y guardado de palabras escuchadas completas |
| Traza la letra | Guías para 27 letras, ratón/táctil y guardado de repeticiones |
| Otras actividades de Lenguaje | Escucha y repite con grabación, Une con imagen, Encuentra la letra y niveles; tres juegos HTML locales y Cóndor Guerrero en escena propia, aportados por el compañero |
| Números | Ocho actividades jugables, 20 misiones y 100 retos; mercado, puentes, comparación y tren; valor posicional, canjes, voz y progreso local |
| Matemáticas | Ocho actividades jugables: cuatro operaciones con 16 misiones y 96 problemas, conteo, ejercicios, doce caminos con plataformas y reto de globos; voz local y progreso persistente |
| Geometría | Menú de figuras y cuatro juegos, llama y voz neuronal; actividades internas pendientes |
| Cuentos | 16 cuentos × 8 escenas; historietas, narración, orden cronológico y 64 preguntas; Carmelo animado, voz masculina local, progreso por actividad y mejor puntuación |
| Elegir personaje (Cuentos) | Juego del compañero integrado: ocho personajes, pistas y partidas de cinco rondas |
| Otros tres juegos inferiores de Cuentos | Completa la escena, Busca el objeto y Reto rápido: mensajes de próxima etapa |
| Diccionario y Enciclopedia | Pantallas provisionales |
| Configuración | Información provisional; todavía no cambia ajustes |
| Personajes 3D | Prototipos independientes, fuera del recorrido principal |

El contador registra **escuchas completadas**, no dominio educativo. Los antiguos registros de visitas se conservan por separado. El trazado verifica la continuidad del recorrido, admite retomar un trazo y muestra el avance real por letras completadas.

## Organización

```text
scenes/             Escena principal y escenas de prototipos
scripts/menu/       Catálogo del menú
scripts/language/   Lección, alfabeto compartido y actividad de trazado
scripts/math/       Menús compartidos y ocho actividades nativas de Matemáticas
scripts/numbers/    Veinte misiones de Números y cuatro minijuegos nativos
scripts/stories/    Repositorio, cuatro modos de cuentos, voz y animación de Carmelo
scripts/prototypes/ Demostraciones 3D
data/language/      Contenido del abecedario
data/math/          Misiones matemáticas, guiones y procedencia de voces
data/numbers/       Misiones, secuencias, comparaciones y narración de Números
data/stories/       Guiones editables y manifiesto de narración
assets/audio/       Grabaciones y felicitaciones
assets/backgrounds/ Fondos
assets/characters/  Personajes y secuencias de animación
assets/stories/     Ocho ilustraciones por cuento, en atlas de 4 × 2
assets/models/      Modelo 3D y textura
assets/ui/          Menú, Lenguaje y trazado
docs/               Análisis, guía de equipo y capturas anteriores
archive/            Arte anterior conservado como referencia
tools/              Auditoría y validación
tests/              Prueba de navegación y guardado en Godot
```

`docs`, `archive` y `tools` tienen `.gdignore`: Godot no los importa como recursos del juego. Se conservaron las ilustraciones y grabaciones originales; se consolidó una grabación exactamente duplicada.

## Documentación

- [Correcciones actuales de Lenguaje y audio](docs/CORRECCIONES_LENGUAJE.md)
- [Cuentos: cuatro actividades, narración y Carmelo](docs/CUENTOS_Y_CARMELO.md)
- [Matemáticas: ocho actividades, controles, capturas y edición](docs/MATEMATICAS_ACTIVIDADES.md)
- [Números: valor posicional, ocho actividades, capturas y edición](docs/NUMEROS_ACTIVIDADES.md)
- [Hack4Edu 2026: encaje, bases y diseño para el reto 02](docs/HACK4EDU_RETO_02.md)
- [Plan de trabajo para el equipo](docs/PLAN_EQUIPO_HACK4EDU.md)
- [Análisis detallado y propuesta de juego e IA](docs/ANALISIS_Y_PROPUESTA.md)
- [Estructura y colaboración](docs/ESTRUCTURA_Y_COLABORACION.md)
- [Cambios y comprobaciones de la limpieza](docs/LIMPIEZA_REALIZADA.md)

## Comprobar cambios

Auditoría de rutas, animaciones y contenido con Python 3.10 o superior:

```powershell
python tools/audit_project.py
```

Validación completa, indicando la ubicación del ejecutable de Godot:

```powershell
./tools/validate.ps1 -Godot 'C:/ruta/a/Godot_console.exe'
```

La validación importa recursos, compila los controladores, recorre Lenguaje y trazado, reconoce un trazo y comprueba el guardado al reabrir. Sus archivos de usuario y registros se aíslan en `.godot/validation/`; no usa el progreso real del jugador.

También comprueba todas las letras con movimientos continuos y eventos espaciados, atajos incorrectos, interrupción de audio, conservación del guardado anterior, dos dedos y navegación después de completar una letra.

Cuentos añade 510 comprobaciones: los 16 recorridos, escenas distintas, audio decodificable, cuatro entradas desde el menú, tarjetas sin recortes, pausa, cancelación y avance automático, orden correcto e incorrecto, pistas, puntuación sin duplicación, conservación del guardado anterior y convivencia con el juego Elegir personaje. Lenguaje y los tres menús matemáticos conservan sus 391 comprobaciones. Se añaden cuatro pruebas de integridad de tiempos de audio al compartir archivos por Git.

Las actividades de Matemáticas añaden 1.003 comprobaciones: 16 misiones, 96 problemas, doce caminos recorridos con física, controles táctiles simultáneos, pistas, reloj, navegación, voces decodificables y guardado parcial compatible. Su revisión visual cubrió 176 composiciones a 1280 × 800 y otras 176 a 960 × 600.

Números añade otras **1.422 comprobaciones** de misiones, canjes, arrastre, conteo táctil, orden, puentes, balanza, tren, reloj, pistas y guardado compatible. El total del proyecto es ahora de **3.326 comprobaciones de Godot y cuatro de Python**. Números tiene revisión visual de 267 composiciones en cada uno de los dos tamaños de ventana. La prueba en Android físico continúa pendiente.

## Generar o cambiar voces

Los audios ya están incluidos: el resto del equipo no necesita generarlos. Para añadir frases, editar `data/audio/voice_lines.json` y ejecutar en Windows:

```powershell
./tools/generate_voice_pack.ps1 -VoiceName Raul -Overwrite
```

Requiere una voz española instalada; no instala voces, modifica el registro ni utiliza servicios externos. Se usa síntesis local Microsoft Raul (México), con procedencia en `data/audio/voice_pack_provenance.json`. Una grabación con mejor interpretación puede reemplazar el archivo correspondiente sin cambiar el código del juego.

No se incluyen todavía instaladores ni perfiles de exportación. Para probar las escenas 3D, abrir `scenes/prototypes/` y ejecutar la escena elegida con F6.
