# Menú de Números

El menú ilustrado de «Números» se abre desde su botón del inicio. Comparte ahora personaje, controlador y voz neuronal con Matemáticas y Geometría; véase [Menús matemáticos](MENUS_MATEMATICOS.md). Lenguaje y Cuentos conservan sus pantallas.

## Incluido

- Fondo del menú preparado por capas: se retiraron los personajes estáticos, la burbuja con un nombre de ejemplo y el progreso ficticio de la referencia.
- Llama independiente con seis fotogramas en un atlas transparente: reposo, tres bocas de habla, parpadeo y sonrisa. El habla usa las bocas mientras suena el audio; es una animación aproximada, sin sincronización de fonemas. El parpadeo y la respiración funcionan en reposo. No se ha asignado un nombre al personaje.
- Once audios MP3 con voz neuronal Camila (español de Perú), distinta a la voz masculina de Conde. No necesitan internet ni voces instaladas en el dispositivo que ejecuta el juego. La bienvenida y cada tema se pueden repetir. No se modificó el paquete de voz de Lenguaje.
- Ocho tarjetas con respuesta visual, foco de teclado y presentación narrada del tema: una, dos, tres y cuatro cifras; contar; secuencias; comparar; reto rápido.
- Ayuda, volumen, silencio persistente y regreso al inicio. Escape cierra una presentación y después permite volver al menú principal.
- Progreso real inicial de cero, sin conceder estrellas por abrir tarjetas. El contador prepara veinte actividades futuras (cinco por bloque de cifras). Todavía no existen ejercicios que incrementen ese contador.
- Fondo y posiciones mantienen la proporción 16:9; las pantallas con otra proporción muestran márgenes para evitar deformar el personaje.

## Alcance pendiente

Las tarjetas muestran una presentación y «Próximamente». Los ejercicios, la evaluación, las recompensas y los retos con tiempo se implementarán en la siguiente entrega. Las ilustraciones de cantidades y bloques del fondo siguen siendo arte de referencia, no modelos de evaluación. La generación de actividades deberá representar correctamente cada cantidad con elementos interactivos.

El menú emite `topic_selected(topic_id)` para conectar las actividades. Sus textos, ejemplos y áreas interactivas están en `scripts/math/numbers_catalog.gd`.

## Archivos

- `scenes/numbers_menu.tscn`: entrada del módulo.
- `scripts/math/numbers_menu.gd`: interfaz, animación, reproducción local y ajustes.
- `assets/ui/math/numbers-menu-background.png`: fondo ilustrado generado a partir de la captura.
- `assets/characters/llama/llama-teacher-atlas.png`: atlas transparente, tres columnas y dos filas. Las regiones se recortan con `AtlasTexture` en Godot; no se duplican las texturas.
- `assets/audio/llama/numbers/`: once MP3 neuronales.
- `data/math/numbers_voice_lines.json`: guion de voz.
- `data/math/numbers_voice_provenance.json`: procedencia de la síntesis.
- `docs/reference/numbers/`: referencias entregadas y prompts completos de las imágenes.

Para regenerar solo esta voz después de preparar el entorno descrito en la guía compartida:

```powershell
./.godot/voice-tools/Scripts/python.exe tools/generate_llama_voice.py --sections numbers
```

Esto usa internet únicamente para preparar los archivos. No cambia los audios de Conde. Los demás integrantes pueden ejecutar el proyecto sin regenerar nada.

## Verificación

`tools/validate.ps1` importa el proyecto, audita las rutas y los audios, y ejecuta `tests/numbers_test.gd` y `tests/learning_sections_test.gd`, además de las pruebas existentes. Comprueba conexiones, audio local, silencio, volumen persistente, progreso, regreso, apertura de Cuentos y ajuste de proporción.

Revisado visualmente en Windows. Pendiente probar en una tablet Android física; no se han generado instaladores ni APK en esta entrega.
