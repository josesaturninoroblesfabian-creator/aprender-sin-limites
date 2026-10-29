# Matemáticas, Números y Geometría

Las tres secciones se abren desde sus botones originales del inicio y comparten la misma llama, la animación y la voz. Lenguaje y Cuentos conservan su implementación y sus audios.

| Sección | Tarjetas principales | Juegos | Progreso |
| --- | --- | --- | --- |
| Matemáticas | Suma, resta, multiplicación y división, con cuatro misiones por operación | Contar, resolver ejercicios, doce caminos y globos, todos jugables | 16 misiones disponibles |
| Números | Una, dos, tres y cuatro cifras, con cinco misiones por grupo | Mercado, puentes, comparación y tren, todos jugables | 20 misiones disponibles |
| Geometría | Figuras, cuerpos 3D, lados y vértices, patrones; cinco misiones por grupo | Safari, telar, contornos y globo, todos jugables | 20 misiones disponibles |

**Matemáticas ya tiene sus ocho actividades internas**, con ejemplos interactivos, 96 problemas, cuatro juegos, progreso y recompensas. Las tarjetas abren `scenes/math_activity.tscn` dentro de Godot. La descripción completa, capturas y guía de edición están en [Actividades de Matemáticas](MATEMATICAS_ACTIVIDADES.md).

**Números también tiene sus ocho actividades internas**, con veinte misiones de valor posicional, cien retos, canjes, cuatro juegos y guardado parcial. Sus tarjetas abren `scenes/number_activity.tscn` dentro de Godot. Ver [Actividades de Números](NUMEROS_ACTIVIDADES.md).

**Geometría también tiene sus ocho actividades internas**, con veinte ejemplos interactivos, cien retos, cuerpos 3D que se giran, piezas para arrastrar y partes para marcar. Sus tarjetas abren `scenes/geometry_activity.tscn`. Guía y capturas en [Actividades de Geometría](GEOMETRIA_ACTIVIDADES.md). No se concede progreso por visitar tarjetas en ninguna de las tres secciones.

## Voz más natural

Se sustituyó la síntesis de escritorio Sabina por **es-PE-CamilaNeural**, voz neuronal de español de Perú. Sigue siendo una voz sintética, no una grabación humana. Se generaron 33 MP3, once por sección, con velocidad ligeramente pausada (-5 %) y tono sin alterar. Los textos se adaptaron a una explicación más conversacional.

Los MP3 están incluidos en `assets/audio/llama/{numbers,mathematics,geometry}/`. El juego reproduce esos archivos sin conectarse a servicios ni necesitar Python. Internet se utilizó únicamente al preparar los audios. No se envían datos de niños ni se genera voz durante el juego.

Las actividades internas de Matemáticas añaden **155 MP3** con la misma voz y velocidad en `assets/audio/llama/activities/`. Su generador es `tools/generate_math_activity_voice.py`; el manifiesto de guiones y firmas está en `data/math/activities_voice_provenance.json`.

Números añade **228 MP3** en `assets/audio/llama/numbers_activities/`, con generador `tools/generate_numbers_activity_voice.py` y manifiesto `data/numbers/voice_provenance.json`. También se reproducen sin conexión y comparten los ajustes de sonido existentes.

Cada archivo tiene un hash y el hash de su texto en `data/math/*_voice_provenance.json`; la auditoría detecta archivos ausentes, cambios o guiones desactualizados. La voz y la versión de la herramienta también quedan documentadas ahí.

Geometría añade **286 MP3** en `assets/audio/llama/geometry_activities/`, preparados por `tools/generate_geometry_activity_voice.py` y documentados en `data/geometry/voice_provenance.json`. Usa la misma voz, reproducción sin conexión y ajustes compartidos.

Fuentes de la herramienta y de la voz: [edge-tts, repositorio del autor](https://github.com/rany2/edge-tts), [voces admitidas por Microsoft](https://learn.microsoft.com/en-us/azure/cognitive-services/speech-service/language-support?tabs=tts).

Los once WAV anteriores de Sabina se trasladaron a `archive/audio/llama-sapi-original/`; se conservan para recuperación y están excluidos de Godot por `archive/.gdignore`.

## Organización compartida

- `scripts/math/numbers_menu.gd` es el controlador compartido. Conserva su nombre para mantener compatibilidad con la primera entrega de Números. Su propiedad `section_id` decide qué sección muestra.
- `scripts/math/learning_sections.gd` asigna fondo, guion, total de actividades y archivo de progreso a cada sección.
- `scripts/math/{numbers,mathematics,geometry}_catalog.gd` contiene las ocho tarjetas y áreas interactivas de cada pantalla.
- Las tres escenas `scenes/{numbers,mathematics,geometry}_menu.tscn` configuran el controlador compartido.
- Un único atlas en `assets/characters/llama/llama-teacher-atlas.png` se reutiliza en las tres secciones. Las bocas se alternan durante la narración; esta animación no sincroniza fonemas.
- Las actividades de Matemáticas reutilizan la llama guía y añaden un atlas de ocho poses de movimiento en `assets/characters/llama/adventure/run-atlas.png`. Sus fondos y objetos están en `assets/ui/math/activities/`.
- `assets/ui/math/` contiene un fondo por sección. Los dos gallos de la referencia de Geometría se retiraron; la llama se dibuja por separado.
- `docs/reference/{numbers,mathematics,geometry}/` guarda referencias, prompts y capturas de la implementación.

El progreso permanece separado: `user://progreso_numeros.cfg`, `user://progreso_matematicas.cfg` y `user://progreso_geometria.cfg`. Los ajustes de voz se comparten en `user://ajustes_numeros.cfg`, conservando la preferencia previa de Números. Cambiar el volumen o silenciar a la guía se aplica a las tres secciones.

Matemáticas conserva los datos anteriores en su archivo y añade la sección `aventura_v1` para intentos, misiones parciales, estrellas, juegos y caminos. El contador de su menú muestra misiones resueltas de las dieciséis disponibles. Salir de una misión o camino permite continuar después.

Números conserva su archivo e identificadores y añade `exploracion_v1` para respuestas, construcciones y órdenes parciales, intentos y récords. Su contador muestra veinte misiones resueltas como máximo. Sus nuevos scripts están en `scripts/numbers/` y los datos en `data/numbers/`.

Geometría conserva los identificadores y datos anteriores de su archivo y añade `exploracion_v1` para respuestas, piezas y marcas parciales, estrellas y récords. Sus scripts están en `scripts/geometry/`, los datos en `data/geometry/` y el arte nuevo en `assets/ui/geometry/activities/`.

El botón de regreso de Geometría reutiliza el recurso de madera existente en Lenguaje. No se modifica dicho recurso. Los menús mantienen proporción 16:9 y Escape permite volver desde las actividades o cerrar las ayudas.

## Regeneración opcional de audio

No hace falta regenerar nada para ejecutar o compartir el juego. Para editar el guion y producir nuevos audios, se necesita internet:

```powershell
python -m venv .godot/voice-tools
./.godot/voice-tools/Scripts/python.exe -m pip install -r tools/voice-requirements.txt
./.godot/voice-tools/Scripts/python.exe tools/generate_llama_voice.py
```

Se puede usar `--sections mathematics`, `--sections numbers` o `--sections geometry` para limitar el lote. El generador comprueba las firmas de los archivos y omite las frases vigentes. `--overwrite` fuerza la regeneración. Si se cambia la voz con `--voice`, hay que generar las tres secciones para conservar una sola identidad vocal.

La herramienta anterior `tools/generate_numbers_voice.ps1` es ahora un acceso compatible al generador neuronal para Números. El generador masculino de Conde (`tools/generate_voice_pack.ps1`) continúa independiente.

## Verificación y pendientes

Las pruebas verifican navegación, las 24 tarjetas, decodificación de los 33 MP3, animación durante el audio, uso compartido del atlas, audio al salir, ajustes persistentes y progreso separado sin cambios al explorar. También se ejecutan las pruebas de Lenguaje y trazado.

Las actividades nuevas de Matemáticas tienen otras 1.003 comprobaciones y revisión visual en dos tamaños de ventana. Incluyen decodificación de los 155 MP3, dieciséis misiones completas, doce caminos con colisiones y puertas, pausa, reloj, dos dedos y conservación del guardado. Los detalles están en su guía.

Números añade 1.510 comprobaciones de sus veinte misiones, cuatro juegos, 228 MP3, canjes, arrastre, pausa y guardado. Tiene revisión visual de 267 composiciones por tamaño de ventana.

Geometría añade 1.441 comprobaciones: veinte misiones, cuatro juegos, cuerpos 3D, 286 MP3, encaje, marcas, patrones, pausa y guardado; 19 usan entrada real de ratón, teclado y toque. Se revisaron 796 composiciones por tamaño de ventana. El total de Godot en el proyecto es **4.855**, además de cuatro pruebas de Python.

Revisado visualmente en Windows. Pendiente probar en una tablet Android física y preparar perfiles de exportación. No se ha publicado ni subido esta entrega a GitHub.
