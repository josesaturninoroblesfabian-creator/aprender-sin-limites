# Cuentos y Carmelo

La sección conserva el menú ilustrado del equipo y sus 16 títulos. Ahora los cuatro botones principales abren actividades reales sobre el mismo cuento. La voz de Carmelo es masculina, peruana y distinta de las voces de Conde y la llama. El juego reproduce archivos incluidos; no solicita internet ni una voz instalada.

## Qué se encontró y qué cambió

El catálogo anterior tenía 15 cuentos de tres páginas y uno de cuatro. Varias páginas repetían la portada; sus resúmenes dejaban saltos entre las acciones. El menú mostraba más actividades de las que estaban conectadas. Se guardó una copia exacta del catálogo anterior en [original_catalog.json](reference/stories/original_catalog.json).

Se prepararon ocho escenas diferentes por cuento, con narración, diálogo corto y relaciones claras entre lo que ocurre antes y después. Cada historia tiene cuatro preguntas vinculadas a escenas concretas. Hay 128 ilustraciones de escenas, 64 preguntas y 64 actividades posibles (16 cuentos × 4 modos).

Son guiones abreviados para esta experiencia educativa. Algunos desenlaces se adaptaron: Caperucita pide ayuda a una guardabosques; Hansel y Gretel escapan y encuentran ayuda; Pinocho ayuda a Gepetto desde un muelle con una pescadora; el flautista consigue que se cumpla lo acordado; el gato ayuda a mejorar un mercado. No son ediciones íntegras de los relatos. Conviene que el equipo docente revise vocabulario y comprensión con niños antes de dar por validada la propuesta pedagógica.

## Los cuatro recorridos

| Botón | Qué hace el niño | Cuándo guarda la actividad |
| --- | --- | --- |
| Cuentos ilustrados | Lee dos viñetas por pantalla, con ilustración, texto y diálogo. Avanza y retrocede a su ritmo. | Tras recorrer las ocho escenas y pulsar «Terminar lectura». |
| Escucha el cuento | Escucha a Carmelo, sigue las palabras resaltadas y puede pausar, repetir o avanzar automáticamente. | Cuando terminan de reproducirse las ocho narraciones. Pausar, silenciar o salir no completa el audio interrumpido. |
| Ordena la historia | Elige cronológicamente cuatro momentos del mismo cuento. Puede deshacer la selección y volver a intentarlo. | Cuando comprueba la secuencia correcta. |
| Preguntas y retos | Responde cuatro preguntas con tres opciones. Puede escuchar pregunta y opciones o volver a la escena que sirve de pista. | Al resolver las cuatro preguntas y terminar. |

Las pestañas superiores permiten cambiar de actividad conservando el cuento. Hay una continuación al terminar lectura, narración u orden. La biblioteca muestra los mismos 16 títulos en cada modo y distingue sus cuatro estados.

Las preguntas dan 10 puntos al primer acierto o 5 después de una respuesta incorrecta. Se conserva el mejor resultado de cada cuento, hasta 40 puntos, con un máximo total de 640. Repetir no acumula puntos indefinidamente. El panel cuenta hasta 64 actividades; recorrer una lectura o escuchar un audio no demuestra por sí solo dominio de la competencia.

Los avances parciales se conservan durante la sesión de ese cuento. Al salir se guardan los modos terminados y el mejor resultado de preguntas. No se guarda todavía un marcador de lectura ni una narración parcialmente escuchada.

## Carmelo y las ilustraciones

- Seis cuadros en un atlas con transparencia: reposo, variaciones del pico y parpadeo. La animación alterna el pico mientras hay voz, se detiene al pausar y añade un balanceo suave. Es una animación por imágenes; no es un modelo 3D ni sincronización fonética.
- Quince cuentos tienen ilustraciones nuevas generadas por IA, ocho momentos por atlas. Pinocho tiene ocho escenas vectoriales editables, derivadas del lenguaje visual de su portada existente; el generador de imágenes rechazó su salida. Su PNG se exportó con Godot desde `assets/stories/pinocho.svg`.
- Se conservan las portadas anteriores y los recursos originales del compañero. La biblioteca usa miniaturas pequeñas de las nuevas escenas y cada actividad carga el atlas de su cuento.
- Referencias y prompts utilizados: [art-provenance.json](reference/stories/art-provenance.json). Las 16 hojas PNG de escenas ocupan aproximadamente 46 MiB; los 205 MP3, 22 MiB. Son tamaños de archivos fuente, no una medición de memoria de una tablet.

## Voz sin conexión

Se incluyen 205 clips: 13 instrucciones de Carmelo, 128 narraciones y 64 lecturas de preguntas. La voz es `es-PE-AlexNeural`, masculina, a velocidad `-8%`. Fue sintetizada durante la preparación de contenido; dentro del juego solo se reproducen MP3 locales.

Cada MP3 tiene un archivo de tiempos por palabra. El manifiesto `data/stories/audio_manifest.json` registra voz, herramienta, fecha y huellas del texto, audio y tiempos. Los ajustes de volumen y silencio pertenecen a Cuentos y no cambian las voces de Lenguaje ni de Matemáticas.

Para jugar basta abrir el proyecto y pulsar F5. Para cambiar frases:

1. Editar `data/stories/library.json` (escenas y preguntas) o `data/stories/carmelo_lines.json` (guía).
2. Reconstruir el catálogo compatible:

   ```powershell
   python tools/prepare_story_library.py
   ```

3. Solo quien genere los audios necesita Python, conexión a internet y las dependencias de `tools/voice-requirements.txt`. En un entorno virtual:

   ```powershell
   python -m venv .godot/voice-tools
   ./.godot/voice-tools/Scripts/python.exe -m pip install -r tools/voice-requirements.txt
   ./.godot/voice-tools/Scripts/python.exe tools/generate_story_audio.py
   ```

   El generador actualiza únicamente los clips cuyo texto, voz o archivos hayan cambiado. `--stories pinocho` limita una regeneración; `--overwrite` la fuerza. Las preguntas se narran en el mismo orden de opciones que muestra el catálogo generado.

4. Revisar las imágenes si cambió una acción y ejecutar la validación completa. Compartir el catálogo, los MP3, tiempos y manifiesto actualizados junto al código.

No editar directamente `assets/data/cuentos.json`: es el catálogo que genera la herramienta y mantiene los identificadores y referencias del módulo del equipo.

## Archivos y guardado

| Archivo | Responsabilidad |
| --- | --- |
| `scripts/cuentos_menu.gd` | Menú ilustrado original, cuatro entradas, ayuda y panel de progreso. |
| `scripts/selector_cuentos.gd` | Biblioteca compartida y estados por modo. |
| `scripts/stories/story_experience.gd` | Lectura, narración, orden y preguntas. |
| `scripts/modo_lectura.gd` | Entrada compatible con la escena anterior del compañero. |
| `scripts/stories/story_repository.gd` | Catálogo, regiones de imágenes, miniaturas y progreso. |
| `scripts/stories/story_audio.gd` | Un reproductor compartido, pausa, cancelación y ajustes de voz. |
| `scripts/stories/carmelo_avatar.gd` | Movimiento por cuadros de Carmelo. |
| `scripts/stories/story_ui.gd` | Controles, contraste, paneles y sonido. |

El nuevo progreso usa la sección `journey_v2` de `user://progreso_cuentos.cfg`. Conserva las demás secciones del archivo y sus copias de recuperación. No convierte antiguas visitas a una tarjeta en actividades completadas. El archivo anterior `cuentos_ilustrados.cfg` se conserva, pero sus marcas no acreditan los nuevos recorridos.

## Comprobación y límites actuales

Validado en Windows con Godot 4.7.2 y Compatibility: auditoría de rutas y contenido, prueba de navegación y 893 comprobaciones automáticas (502 de Cuentos y 391 de Lenguaje/Números/Matemáticas/Geometría), sin fallos. Las pruebas aíslan los archivos de usuario en `.godot/validation/`.

Se revisaron las pantallas con el renderizador real, las 64 dobles páginas y las 64 preguntas, además de la biblioteca, narración, resultado y sonido. Las capturas son del juego, no maquetas. También se revisa la presentación a 960 × 600.

No se ha probado todavía en un dispositivo Android físico ni se han generado instaladores. Al preparar una exportación se deben incluir los JSON del catálogo y de tiempos en el filtro de archivos sin recurso (por ejemplo, `*.json`). El proyecto aún no tiene perfiles de exportación.

Los cuatro juegos inferiores —Elegir personaje, Completa la escena, Busca el objeto y Reto rápido— siguen mostrando su aviso de próxima etapa. No forman parte de estos cuatro recorridos principales. Tampoco se añadió una IA que razone durante el juego ni sincronización con servidor.

## Capturas del resultado

- [Menú con Carmelo](reference/stories/menu.png)
- [Biblioteca](reference/stories/library.png)
- [Leer en viñetas](reference/stories/read.png)
- [Escuchar y seguir el texto](reference/stories/listen.png)
- [Ordenar sucesos](reference/stories/order.png)
- [Preguntas](reference/stories/quiz.png)
- [Resultado](reference/stories/result.png)
- [Sonido](reference/stories/sound.png)
