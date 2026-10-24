# Matemáticas, Números y Geometría

Las tres secciones se abren desde sus botones originales del inicio y comparten la misma llama, la animación y la voz. Lenguaje y Cuentos conservan su implementación y sus audios.

| Sección | Tarjetas principales | Juegos presentados | Progreso reservado |
| --- | --- | --- | --- |
| Matemáticas | Suma, resta, multiplicación y división | Contar, resolver ejercicios, niveles y reto rápido | 16 actividades |
| Números | Una, dos, tres y cuatro cifras | Contar, secuencias, comparar y reto rápido | 20 actividades |
| Geometría | Figuras planas, cuerpos geométricos, lados y vértices, patrones | Buscar figuras, armar patrones, contar lados y reto rápido | 20 actividades |

Por ahora cada tarjeta abre una presentación con ejemplo, descripción y narración. Los submenús, ejercicios y recompensas se construirán de uno en uno con los siguientes diseños del equipo. No se concede progreso por visitar tarjetas. Los totales son plazas previstas para futuras actividades; todavía no representan ejercicios disponibles.

## Voz más natural

Se sustituyó la síntesis de escritorio Sabina por **es-PE-CamilaNeural**, voz neuronal de español de Perú. Sigue siendo una voz sintética, no una grabación humana. Se generaron 33 MP3, once por sección, con velocidad ligeramente pausada (-5 %) y tono sin alterar. Los textos se adaptaron a una explicación más conversacional.

Los MP3 están incluidos en `assets/audio/llama/{numbers,mathematics,geometry}/`. El juego reproduce esos archivos sin conectarse a servicios ni necesitar Python. Internet se utilizó únicamente al preparar los audios. No se envían datos de niños ni se genera voz durante el juego.

Cada archivo tiene un hash y el hash de su texto en `data/math/*_voice_provenance.json`; la auditoría detecta archivos ausentes, cambios o guiones desactualizados. La voz y la versión de la herramienta también quedan documentadas ahí.

Fuentes de la herramienta y de la voz: [edge-tts, repositorio del autor](https://github.com/rany2/edge-tts), [voces admitidas por Microsoft](https://learn.microsoft.com/en-us/azure/cognitive-services/speech-service/language-support?tabs=tts).

Los once WAV anteriores de Sabina se trasladaron a `archive/audio/llama-sapi-original/`; se conservan para recuperación y están excluidos de Godot por `archive/.gdignore`.

## Organización compartida

- `scripts/math/numbers_menu.gd` es el controlador compartido. Conserva su nombre para mantener compatibilidad con la primera entrega de Números. Su propiedad `section_id` decide qué sección muestra.
- `scripts/math/learning_sections.gd` asigna fondo, guion, total de actividades y archivo de progreso a cada sección.
- `scripts/math/{numbers,mathematics,geometry}_catalog.gd` contiene las ocho tarjetas y áreas interactivas de cada pantalla.
- Las tres escenas `scenes/{numbers,mathematics,geometry}_menu.tscn` configuran el controlador compartido.
- Un único atlas en `assets/characters/llama/llama-teacher-atlas.png` se reutiliza en las tres secciones. Las bocas se alternan durante la narración; esta animación no sincroniza fonemas.
- `assets/ui/math/` contiene un fondo por sección. Los dos gallos de la referencia de Geometría se retiraron; la llama se dibuja por separado.
- `docs/reference/{numbers,mathematics,geometry}/` guarda referencias, prompts y capturas de la implementación.

El progreso permanece separado: `user://progreso_numeros.cfg`, `user://progreso_matematicas.cfg` y `user://progreso_geometria.cfg`. Los ajustes de voz se comparten en `user://ajustes_numeros.cfg`, conservando la preferencia previa de Números. Cambiar el volumen o silenciar a la guía se aplica a las tres secciones.

El botón de regreso de Geometría reutiliza el recurso de madera existente en Lenguaje. No se modifica dicho recurso. Las pantallas mantienen proporción 16:9, tienen foco de teclado y permiten cerrar las presentaciones con Escape.

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

Revisado visualmente en Windows. Pendiente probar en una tablet Android física y preparar perfiles de exportación. No se ha publicado ni subido esta entrega a GitHub.
