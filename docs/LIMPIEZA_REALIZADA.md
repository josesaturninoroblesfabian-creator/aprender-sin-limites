# Limpieza y verificación — 23 de octubre de 2026

## Estado inicial preservado

Antes de intervenir había cambios locales en `project.godot` y siete descriptores de audio. Se conservó la versión configurada 4.7; no se revirtió a la versión anterior del repositorio ni se sobrescribió el contenido educativo del compañero.

No se crearon commits, no se publicaron cambios en GitHub y no se modificó el historial. Los movimientos aparecen como archivos retirados y archivos nuevos hasta que Git los compara al preparar los cambios.

## Trabajo realizado

1. Se separaron los scripts de Lenguaje y trazado de los prototipos 3D.
2. Se ordenaron recursos en audio, fondos, personajes, modelos e interfaz. Se actualizaron referencias estáticas, plantillas de fotogramas y descriptores de importación, conservando los UID existentes.
3. El abecedario pasó a `data/language/`; no se cambiaron sus 270 ejemplos.
4. Se centralizó la lista de letras y se extrajeron las formas de trazado del controlador de pantalla. Se mantuvieron sus coordenadas y criterios de reconocimiento.
5. Se centralizaron nombres, iconos y posiciones del menú en un catálogo. Se conservaron diseño y posiciones actuales.
6. Se retiraron del inicio el banco de palabras y tres manejadores de un juego anterior que ya no tenían pantalla ni llamadas activas. Se retiró un auxiliar de color sin uso.
7. Cinco capturas de la raíz se trasladaron a `docs/reference/`. Diez imágenes y SVG sin llamadas en el juego se conservaron en `archive/art/`. Estas carpetas no se importan al juego.
8. Se retiraron ocho archivos `.import` cuyo original ya no existía. Se conservan los descriptores de recursos activos.
9. Se consolidó una grabación exactamente duplicada; el prototipo y el inicio apuntan al mismo MP3. No se eliminaron fotogramas repetidos de las animaciones.
10. Se añadieron reglas de edición, finales de línea, exclusión de resultados locales y herramientas de validación.
11. Se actualizó el README para distinguir funciones operativas y pantallas provisionales.

## Correcciones pequeñas incluidas

- Volver desde trazado conserva abierta la lección de Lenguaje y la letra seleccionada. El botón tiene ahora texto editable «Volver a Lenguaje», coherente con el destino.
- Se eliminaron desplazamientos accidentales de tres píxeles en la escena raíz.
- El total de palabras se calcula a partir del contenido; dejó de depender de una constante de 270.
- Los errores al guardar generan un aviso del motor, en lugar de quedar ignorados.
- Se retiró una etiqueta de marca construida sin añadirse al árbol. Se confirmó que producía recursos sin liberar al abrir y cerrar la lección.

## Evidencia de conservación

Se compararon mediante SHA-256 los 500 archivos originales de imágenes, SVG, audio, modelo y datos, incluidos los cinco PNG de referencia. Todos conservan su contenido; el audio duplicado se comprobó contra su copia compartida. Los cambios de importación corresponden a las nuevas rutas y a la reimportación del motor.

La carpeta activa de recursos pasó de aproximadamente 104,96 MiB a 102,43 MiB. Parte de la diferencia corresponde al archivo de referencia: no es una optimización del consumo de memoria. No se reescribió el historial de Git ni se redujo su tamaño histórico.

## Verificación

- Importación con Godot 4.7.2 Compatibility.
- Auditoría de referencias exactas, UID, 404 fotogramas, 27 imágenes de trazado y 270 ejemplos.
- Compilación de los controladores activos y de los scripts de prototipos.
- Prueba automática de navegación, recorrido válido de los trazos de A, guardado y reapertura.
- Comprobación visual de inicio, Lenguaje y trazado a 1280 × 800 con OpenGL en este equipo.
- Pruebas con carpetas de usuario aisladas dentro de `.godot/validation/`.

Los comandos reproducibles figuran en el README. Las limitaciones educativas se documentan en `ANALISIS_Y_PROPUESTA.md`; no se presentan como corregidas por esta limpieza.

No se validaron instaladores, otros sistemas operativos, pantallas pequeñas, voces de otros equipos ni uso táctil físico. Las escenas 3D se conservaron como prototipos; no se rediseñaron sus personajes o animaciones.
