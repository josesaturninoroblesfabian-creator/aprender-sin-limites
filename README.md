# Aprende sin Límites

Juego educativo en Godot para explorar letras y practicar su trazado, con personajes y ambientación andina. Su público previsto es inicial y primaria; la implementación actual se concentra en alfabetización inicial.

## Ejecutar

1. Importar `project.godot` en Godot. La limpieza se verificó con **Godot 4.7.2**, usando el renderizador Compatibility.
2. Esperar la importación de imágenes, audio y modelo 3D.
3. Pulsar **F5** para ejecutar el proyecto completo. F6 ejecuta solo la escena abierta.

Se conserva el estilo ilustrado original: fondos, botones y personajes por imágenes. Incluye **300 audios locales en español** (270 palabras, 27 letras y tres instrucciones); no necesita una voz española instalada para reproducirlos. No hay reconocimiento de voz ni una IA integrada actualmente.

## Estado real

| Área | Implementado |
| --- | --- |
| Inicio | Menú, saludos grabados, animaciones y despedida |
| Lenguaje | 27 letras, 10 ejemplos por letra, audio incluido y guardado de palabras escuchadas completas |
| Traza la letra | Guías para 27 letras, ratón/táctil y guardado de repeticiones |
| Otras cuatro actividades de Lenguaje | Botones con mensaje de futura disponibilidad |
| Matemática, Números, Geometría, Cuentos, Diccionario y Enciclopedia | Pantallas provisionales |
| Configuración | Información provisional; todavía no cambia ajustes |
| Personajes 3D | Prototipos independientes, fuera del recorrido principal |

El contador registra **escuchas completadas**, no dominio educativo. Los antiguos registros de visitas se conservan por separado. El trazado verifica la continuidad del recorrido, admite retomar un trazo y muestra el avance real por letras completadas.

## Organización

```text
scenes/             Escena principal y escenas de prototipos
scripts/menu/       Catálogo del menú
scripts/language/   Lección, alfabeto compartido y actividad de trazado
scripts/prototypes/ Demostraciones 3D
data/language/      Contenido del abecedario
assets/audio/       Grabaciones y felicitaciones
assets/backgrounds/ Fondos
assets/characters/  Personajes y secuencias de animación
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

## Generar o cambiar voces

Los audios ya están incluidos: el resto del equipo no necesita generarlos. Para añadir frases, editar `data/audio/voice_lines.json` y ejecutar en Windows:

```powershell
./tools/generate_voice_pack.ps1 -VoiceName Raul -Overwrite
```

Requiere una voz española instalada; no instala voces, modifica el registro ni utiliza servicios externos. Se usa síntesis local Microsoft Raul (México), con procedencia en `data/audio/voice_pack_provenance.json`. Una grabación con mejor interpretación puede reemplazar el archivo correspondiente sin cambiar el código del juego.

No se incluyen todavía instaladores ni perfiles de exportación. Para probar las escenas 3D, abrir `scenes/prototypes/` y ejecutar la escena elegida con F6.
