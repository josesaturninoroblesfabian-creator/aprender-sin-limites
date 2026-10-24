# Estructura y trabajo en equipo

## Dónde se modifica cada cosa

| Necesidad | Archivo o carpeta |
| --- | --- |
| Inicio, bienvenida y navegación global | `scripts/main.gd` y `scenes/main.tscn` |
| Nombres, iconos y ubicación de botones del inicio | `scripts/menu/menu_catalog.gd` |
| Pantalla de Lenguaje | `scripts/language/language_lesson.gd` |
| Alfabeto compartido, incluida Ñ | `scripts/language/alphabet.gd` |
| Palabras e ilustraciones de los ejemplos | `data/language/abecedario.json` |
| Pantalla y repeticiones de trazado | `scripts/language/tracing/trace_exercise.gd` |
| Reconocimiento y dibujo del trazo | `scripts/language/tracing/trace_canvas.gd` |
| Formas normalizadas de las letras | `scripts/language/tracing/letter_strokes.gd` |
| Demostraciones 3D | `scenes/prototypes/` y `scripts/prototypes/` |
| Imágenes y audio utilizados | `assets/`, organizado por función |
| Material anterior sin uso en el juego | `archive/art/` |
| Capturas antiguas | `docs/reference/` |

Los nombres originales de muchos recursos se conservan para facilitar su reconocimiento. Las rutas se actualizaron tanto en código como en los descriptores de importación.

## Mapa de rutas

| Antes | Ahora |
| --- | --- |
| `scripts/language_lesson.gd` | `scripts/language/language_lesson.gd` |
| `scripts/trace_exercise.gd` | `scripts/language/tracing/trace_exercise.gd` |
| `scripts/trace_canvas.gd` | `scripts/language/tracing/trace_canvas.gd` |
| Scripts y escenas 3D en la raíz de sus carpetas | Subcarpeta `prototypes/` |
| `assets/abecedario.json` | `data/language/abecedario.json` |
| MP3 sueltos y `assets/felicitaciones/` | `assets/audio/` y `assets/audio/praise/` |
| `assets/fondo-*` | `assets/backgrounds/` |
| `assets/icons/` | `assets/ui/menu/` |
| `assets/trace-letters/` | `assets/ui/tracing/letters/` |
| `assets/condor-frames/` | `assets/characters/condor/frames/` |
| `assets/nina-gif/` | `assets/characters/nina/welcome/` |
| `assets/nina-despedida-gif/` | `assets/characters/nina/goodbye/` |
| `assets/nino-gif/` | `assets/characters/nino/welcome/` |
| Imágenes estáticas de niña y niño | `assets/characters/nina/` y `assets/characters/nino/` |
| Modelo GLB y textura | `assets/models/` |
| Imágenes de Lenguaje y trazado sueltas | `assets/ui/language/` y `assets/ui/tracing/` |

`pregunta-nino.mp3` era idéntico a `audio-nino.mp3`. El prototipo utiliza ahora la misma grabación del inicio, en `assets/audio/audio-nino.mp3`.

## Coordinar la próxima edición

Antes de que el compañero continúe Lenguaje, compartir esta reorganización completa, incluidos archivos nuevos y movimientos de recursos. Evitar intercambiar solo un script: sus rutas dependen del resto del cambio.

Si existe trabajo suyo sin compartir, conservarlo y combinar los cambios usando el mapa anterior. No reemplazar la carpeta completa de Lenguaje por una copia antigua. Cuando ambos tengan la limpieza, trabajar en ramas por tarea, por ejemplo `codex/actividad-unir-imagen` y `codex/menu-aventura`, y revisar el recorrido principal antes de integrar cada cambio.

Para reducir conflictos, una persona puede continuar contenido y actividades de Lenguaje mientras otra trabaja en inicio, navegación y componentes comunes. Acordar antes los cambios a `alphabet.gd`, al formato de datos y a los guardados.

## Convenciones

- Carpetas y scripts nuevos en `snake_case`; nodos en `PascalCase`.
- Tabulaciones para GDScript; UTF-8 y finales LF. `.editorconfig` y `.gitattributes` fijan estas reglas.
- Mantener `.gd.uid` y `.import` junto a los recursos activos: contienen identidades y opciones de importación. No ignorarlos de forma general.
- No compartir `.godot/`: es caché local. Tampoco credenciales de exportación o resultados de compilación.
- Mover recursos desde el editor cuando sea posible. Si se hace fuera, actualizar las rutas dinámicas y comprobar referencias.
- Reservar `user://` para progreso. Se mantienen `progreso_lenguaje.cfg` y `progreso_traza_letras.cfg` y sus secciones actuales.
- Mantener contenido educativo separado del dibujo de pantalla. Conservar identificadores estables al evolucionar el progreso; hoy los ejemplos todavía se identifican por posición en su lista.
- Las animaciones contienen fotogramas visualmente repetidos a propósito. No borrarlos solo por tener la misma imagen.

## Antes de compartir

Ejecutar la auditoría y validación del README. Probar además el cambio visual con F5: una prueba sin interfaz no verifica comprensión infantil, voces instaladas, calidad visual ni dispositivos táctiles reales.

La prueba automática recorre menú, Ñ y sus ejemplos, un trazo válido de A, vuelta a Lenguaje, una pantalla provisional y recuperación del progreso de trazado. No constituye una validación pedagógica de todas las letras.
